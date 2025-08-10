#!/bin/bash

# B200

export REGION="asia-southeast1"
export ZONE="asia-southeast1-b"
export PROJECT="gpu-launchpad-playground"
export PROJECT_NUMBER="604327164091"
export GKE_VERSION="1.32.4-gke.1767000"
export CLUSTER_NAME="gke-inference-sin"
export NODEPOOL_NAME="b200-ccc"
export ACCELERATOR_TYPE="nvidia-b200"
export AMOUNT=8 # can only be 8
export MACHINE_TYPE="a4-highgpu-8g"
export NUM_NODES=0 # Must be set to 0 for flex-start to initialise 0 sized nodepool
export TOTAL_MAX_NODES=2 # Max number of nodes that can scale up in nodepool for flex-start. Could be upto 1000 VMs (8k GPUs)
export DRIVER_VERSION="latest"
export WORKLOAD_IDENTITY=$PROJECT.svc.id.goog
export BUCKET_NAME="ikwak-stuff"
export KSA_NAME="gke-ksa"
export HF_TOKEN="" # Update


gcloud container clusters create $CLUSTER_NAME \
  --region=$REGION \
  --cluster-version=$GKE_VERSION \
  --addons=GcsFuseCsiDriver,HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS \
  --enable-managed-prometheus \
  --machine-type=e2-standard-32 \
  --node-locations=$ZONE \
  --num-nodes=2 \
  --workload-pool $WORKLOAD_IDENTITY

# 8 x B200 nodepool
  gcloud container node-pools create $NODEPOOL_NAME \
  --region $REGION \
  --cluster $CLUSTER_NAME \
  --node-locations $ZONE \
  --accelerator type=$ACCELERATOR_TYPE,count=$AMOUNT,gpu-driver-version=$DRIVER_VERSION \
  --machine-type $MACHINE_TYPE \
  --num-nodes=$NUM_NODES \
  --flex-start --num-nodes=0 --enable-autoscaling \
  --total-max-nodes $TOTAL_MAX_NODES \
  --no-enable-autorepair --location-policy=ANY \
  --reservation-affinity=none \
  --node-labels="cloud.google.com/compute-class=b200-ccc" \
  --node-taints="cloud.google.com/compute-class=b200-ccc:NoSchedule"

# Authenticate with cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Set up CCC
kubectl apply -f b200-ccc.yaml

# Create KSA for GCS access
kubectl create serviceaccount $KSA_NAME

# Grant KSA read-write access to bucket
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME --member "principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WORKLOAD_IDENTITY/subject/ns/default/sa/$KSA_NAME"   --role "roles/storage.admin"

# Create secret for HF
kubectl create secret generic hf-secret   --from-literal=hf_api_token=${HF_TOKEN}   --dry-run=client -o yaml | kubectl apply -f -