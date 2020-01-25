kubectl apply -f pods.yaml

echo 'Test 1: each pod has an IP address'
kubectl get pods -o wide -w

echo 'Test 2: pods on the same node can reach eachother without NAT'
kubectl exec -ti pod-1 my-nping 200.200.2.5

echo 'Test 3: pods on different nodes can reach eachother without NAT'
kubectl exec -ti pod-1 my-nping 200.200.1.4

echo 'Test 4: node agents can reach pods on the same node without NAT'
gcloud compute ssh root@my-k8s-worker-1 --command "curl https://raw.githubusercontent.com/learnk8s/docker-advanced-networking/master/my-nping >my-nping"
gcloud compute ssh root@my-k8s-worker-1 --command "chmod +x my-nping"
gcloud compute ssh root@my-k8s-worker-1 --command "./my-nping 200.200.1.4"

echo 'Test 5: node agents can reach pods on a different node without NAT'
gcloud compute ssh root@my-k8s-worker-1 --command "./my-nping 200.200.2.5"

echo 'Test 6: pods can reach the internet'
kubectl exec -ti pod-1 my-nping echo.nmap.org
