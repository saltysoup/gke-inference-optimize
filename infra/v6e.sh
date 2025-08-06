#!/bin/bash


# v6e-1

export REGION="asia-northeast1"
export ZONE="asia-northeast1-b"
export PROJECT="gpu-launchpad-playground"
export PROJECT_NUMBER="604327164091"
export GKE_VERSION="1.33.2-gke.1240000"
export CLUSTER_NAME="gke-inference-jp"
export NODEPOOL_NAME="v6e-ccc"
export ACCELERATOR_TYPE="tpu-v6e-slice"
export AMOUNT=1
export MACHINE_TYPE="ct6e-standard-1t"
export NUM_NODES=0 # Must be set to 0 for flex-start to initialise 0 sized nodepool
export TOTAL_MAX_NODES=2 # Max number of nodes that can scale up in nodepool for flex-start. Could be upto 1000 VMs (8k GPUs)
export DRIVER_VERSION="latest"
export WORKLOAD_IDENTITY=$PROJECT.svc.id.goog
export BUCKET_NAME="ikwak-stuff"
export KSA_NAME="gke-ksa"



gcloud container clusters create $CLUSTER_NAME \
  --region=$REGION \
  --cluster-version=$GKE_VERSION \
  --addons=GcsFuseCsiDriver,HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS \
  --enable-managed-prometheus \
  --machine-type=e2-standard-32 \
  --node-locations=$ZONE \
  --num-nodes=2 \
  --workload-pool $WORKLOAD_IDENTITY

# v6e-1 nodepool
  gcloud container node-pools create $NODEPOOL_NAME \
  --region $REGION \
  --cluster $CLUSTER_NAME \
  --node-locations $ZONE \
  --machine-type $MACHINE_TYPE \
  --num-nodes=$NUM_NODES \
  --enable-autoscaling \
  --flex-start --num-nodes=0 \
  --min-nodes=$NUM_NODES --max-nodes=$TOTAL_MAX_NODES \
  --reservation-affinity=none 

# Authenticate with cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Create KSA for GCS access
kubectl create serviceaccount $KSA_NAME

# Grant KSA read-write access to bucket
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME --member "principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WORKLOAD_IDENTITY/subject/ns/default/sa/$KSA_NAME"   --role "roles/storage.admin"
