gcloud -q compute routes delete my-k8s-master my-k8s-worker-1 my-k8s-worker-2
gcloud -q compute instances delete my-k8s-master my-k8s-worker-1 my-k8s-worker-2
gcloud -q compute firewall-rules delete my-k8s-internal my-k8s-ingress
gcloud -q compute networks subnets delete my-k8s-subnet
gcloud -q compute networks delete my-k8s-vpc
