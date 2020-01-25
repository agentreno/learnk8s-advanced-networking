{
  "cniVersion": "0.3.1",
  "name": "my-pod-network",
  "type": "my-cni-plugin",
  "myHostNet": "10.0.0.0/16",
  "myPodNet": "200.200.0.0/16",
  "myPodNodeSubnet": std.extVar("podNodeSubnet")
}
