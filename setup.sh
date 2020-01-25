# Networks
gcloud compute networks create my-k8s-vpc --subnet-mode custom
gcloud compute networks subnets create my-k8s-subnet --network my-k8s-vpc --range 10.0.0.0/16

# Instances
gcloud compute instances create my-k8s-master \
    --machine-type n1-standard-2 \
    --subnet my-k8s-subnet \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --can-ip-forward

gcloud compute instances create my-k8s-worker-1 my-k8s-worker-2 \
    --machine-type n1-standard-1 \
    --subnet my-k8s-subnet \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --can-ip-forward

gcloud compute firewall-rules create my-k8s-internal \
    --network my-k8s-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 10.0.0.0/16,200.200.0.0/16

gcloud compute firewall-rules create my-k8s-ingress \
    --network my-k8s-vpc \
    --allow tcp:22,tcp:6443

# Install kubeadm on all
for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  gcloud compute scp install-kubeadm.sh "$node":
  gcloud compute ssh "$node" --command "chmod +x install-kubeadm.sh"
  gcloud compute ssh "$node" --command "./install-kubeadm.sh"
done

# Verify installation
for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  gcloud compute ssh "$node" --command "kubeadm version"
done

MASTER_EXTERNAL_IP=$(gcloud compute instances describe my-k8s-master \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

# Create the master with kubeadm
gcloud compute ssh my-k8s-master --command \
  "sudo kubeadm init --apiserver-cert-extra-sans=\"$MASTER_EXTERNAL_IP\" --pod-network-cidr=200.200.0.0/16"

# Download the kubeconfig
gcloud compute scp root@my-k8s-master:/etc/kubernetes/admin.conf my-kubeconfig

# Replace the IP of the apiserver with the master external IP instead of internal
sed -i -r "s#[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:6443#$MASTER_EXTERNAL_IP:6443#" my-kubeconfig

# Install jq and nmap on the nodes for the CNI and connectivity testing
for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  gcloud compute ssh "$node" --command "sudo apt-get -y install jq nmap"
done

# Create host network routes for the pod network
for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  node_ip=$(kubectl get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  pod_node_subnet=$(kubectl get node "$node" -o jsonpath='{.spec.podCIDR}')
  gcloud compute routes create "$node" --network=my-k8s-vpc --destination-range="$pod_node_subnet" \
    --next-hop-address="$node_ip"
done
