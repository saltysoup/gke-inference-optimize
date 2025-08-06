#!/bin/bash

# H100

export REGION="us-central1"
export ZONE="us-central1-a"
export PROJECT="gpu-launchpad-playground"
export PROJECT_NUMBER="604327164091"
export GKE_VERSION="1.32.4-gke.1767000"
export CLUSTER_NAME="gke-inference-us"
export NODEPOOL_NAME_1="h100-ccc-1"
export NODEPOOL_NAME_8="h100-ccc-8"
export ACCELERATOR_TYPE="nvidia-h100-80gb"
export AMOUNT_1=1 # can be 1, 2, 4, 8
export AMOUNT_8=8 # can be 1, 2, 4, 8
export MACHINE_TYPE_1="a3-highgpu-1g"
export MACHINE_TYPE_8="a3-highgpu-8g"
export NUM_NODES=0 # Must be set to 0 for flex-start to initialise 0 sized nodepool
export TOTAL_MAX_NODES=2 # Max number of nodes that can scale up in nodepool for flex-start. Could be upto 1000 VMs (8k GPUs)
export DRIVER_VERSION="latest"
export WORKLOAD_IDENTITY=$PROJECT.svc.id.goog
export BUCKET_NAME="ikwak-stuff"
export KSA_NAME="gke-ksa"

# Create GKE cluster

gcloud container clusters create $CLUSTER_NAME \
  --region=$REGION \
  --cluster-version=$GKE_VERSION \
  --addons=GcsFuseCsiDriver,HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS \
  --enable-managed-prometheus \
  --machine-type=e2-standard-32 \
  --node-locations=$ZONE \
  --num-nodes=2 \
  --workload-pool $WORKLOAD_IDENTITY

  # Create 2 x nodepools for each model

# 1 x H100 nodepool
  gcloud container node-pools create $NODEPOOL_NAME_1 \
  --region $REGION \
  --cluster $CLUSTER_NAME \
  --node-locations $ZONE \
  --accelerator type=$ACCELERATOR_TYPE,count=$AMOUNT_1,gpu-driver-version=$DRIVER_VERSION \
  --machine-type $MACHINE_TYPE_1 \
  --num-nodes=$NUM_NODES \
  --flex-start --num-nodes=0 --enable-autoscaling \
  --total-max-nodes $TOTAL_MAX_NODES \
  --no-enable-autorepair --location-policy=ANY \
  --reservation-affinity=none \
  --node-labels="cloud.google.com/compute-class=h100-ccc" \
  --node-taints="cloud.google.com/compute-class=h100-ccc:NoSchedule"

# 8 x H100 nodepool
  gcloud container node-pools create $NODEPOOL_NAME_8 \
  --region $REGION \
  --cluster $CLUSTER_NAME \
  --node-locations $ZONE \
  --accelerator type=$ACCELERATOR_TYPE,count=$AMOUNT_8,gpu-driver-version=$DRIVER_VERSION \
  --machine-type $MACHINE_TYPE_8 \
  --num-nodes=$NUM_NODES \
  --flex-start --num-nodes=0 --enable-autoscaling \
  --total-max-nodes $TOTAL_MAX_NODES \
  --no-enable-autorepair --location-policy=ANY \
  --reservation-affinity=none \
  --node-labels="cloud.google.com/compute-class=h100-ccc" \
  --node-taints="cloud.google.com/compute-class=h100-ccc:NoSchedule"

# Authenticate with cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Set up CCC
kubectl apply -f h100-ccc.yaml
#kubectl apply -f h100-ccc-8.yaml

# Create KSA for GCS access
kubectl create serviceaccount $KSA_NAME

# Grant KSA read-write access to bucket
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME --member "principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WORKLOAD_IDENTITY/subject/ns/default/sa/$KSA_NAME"   --role "roles/storage.admin"
