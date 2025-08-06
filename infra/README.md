## Infra provisioning

1. Set env var for our cloud resources

```
export REGION="asia-southeast1"
export ZONE="asia-southeast1-b"
export PROJECT="gpu-launchpad-playground"
export PROJECT_NUMBER="604327164091"
export GKE_VERSION="1.32.4-gke.1767000"
export CLUSTER_NAME="gke-inference"
export COMPUTE_REGION=$REGION
export NODEPOOL_NAME_H100="h100-dws"
export NODEPOOL_NAME_SPOT="h200-spot-ccc"
export GPU_TYPE="nvidia-h200-141gb"
export AMOUNT=8 # Number of GPUs to attach per VM
export MACHINE_TYPE="a3-ultragpu-8g"
export NUM_NODES=0 # Must be set to 0 for flex-start to initialise 0 sized nodepool
export TOTAL_MAX_NODES=10 # Max number of nodes that can scale up in nodepool for flex-start. Could be upto 1000 VMs (8k GPUs)
export DRIVER_VERSION="latest"
export WORKLOAD_IDENTITY=$PROJECT.svc.id.goog
export BUCKET_NAME="nearmap-ray"
export KSA_NAME="nearmap-ray"
export SECRET_NAME="test"
```
