#!/bin/bash

export PROJECT="gpu-launchpad-playground"
export CLUSTER_NAME="gke-inference-us"
export REGION="us-central1"

# Authenticate with cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Create AR repo
gcloud artifacts repositories create gke-inference --repository-format=docker --location=$REGION && gcloud auth configure-docker $REGION-docker.pkg.dev

# Build benchmark client container
cd ../docker
DOCKER_BUILDKIT=1 docker build -f Dockerfile . -t $REGION-docker.pkg.dev/$PROJECT/gke-inference/benchmark-client:latest
docker push $REGION-docker.pkg.dev/$PROJECT/gke-inference/benchmark-client:latest

# run benchmarking
kubectl apply -f benchmark-235b-a22b.yaml

# get results
kubectl logs -f job/vllm-benchmark-235b-a22b