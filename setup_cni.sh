for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  gcloud compute scp my-cni-plugin/my-cni-plugin.py root@"$node":/opt/cni/bin
done

for node in my-k8s-master my-k8s-worker-1 my-k8s-worker-2; do
  tmp=$(mktemp -d)/my-cni-plugin.conf
  jsonnet -V podNodeSubnet="$(kubectl get node "$node" -o jsonpath='{.spec.podCIDR}')" my-cni-plugin/my-cni-plugin.conf.jsonnet >$tmp
  gcloud compute ssh root@"$node" --command "mkdir -p /etc/cni/net.d"
  gcloud compute scp "$tmp" root@"$node":/etc/cni/net.d
done
