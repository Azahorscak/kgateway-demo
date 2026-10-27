# EKS cluster

```sh
eksctl create cluster -f cluster.yaml
```

Then install the AWS Load Balancer Controller, which turns the kgateway
`Service` into an NLB (the in-tree controller would give you a Classic LB):

```sh
helm repo add eks https://aws.github.io/eks-charts
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ambient-kgateway \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## EKS things that bite ambient

- **Security groups for pods.** If you use `SecurityGroupPolicy` (pod ENI
  trunking), set `POD_SECURITY_GROUP_ENFORCING_MODE=standard` on the
  `aws-node` DaemonSet. In the default `strict` mode, kubelet health probes —
  which ambient rewrites to come from a link-local address — are dropped and
  every enrolled pod fails readiness.
- **Node security group.** ztunnel-to-ztunnel traffic is HBONE on TCP 15008.
  The default eksctl node group allows all node-to-node traffic; if you
  tightened it, open 15008 between nodes.
- **VPC CNI network policy.** If you enable the VPC CNI's own NetworkPolicy
  enforcement, allow 15008 and the probe source `169.254.7.127/32`.
- **Bottlerocket / custom AMIs.** istio-cni writes into `/opt/cni/bin` and
  `/etc/cni/net.d`; both are the VPC CNI defaults, so no override is needed on
  AL2023. Check the paths if you run something else.

Docs: <https://istio.io/latest/docs/ambient/install/platform-prerequisites/#amazon-elastic-kubernetes-service-eks>
