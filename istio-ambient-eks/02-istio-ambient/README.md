# Istio ambient

Four charts from `https://istio-release.storage.googleapis.com/charts`, in this
order. All go into `istio-system`.

```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
export ISTIO_VERSION=1.27.1

helm upgrade -i istio-base istio/base -n istio-system --create-namespace \
  --version $ISTIO_VERSION --wait

helm upgrade -i istiod istio/istiod -n istio-system \
  --version $ISTIO_VERSION -f istiod-values.yaml --wait

helm upgrade -i istio-cni istio/cni -n istio-system \
  --version $ISTIO_VERSION -f cni-values.yaml --wait

helm upgrade -i ztunnel istio/ztunnel -n istio-system \
  --version $ISTIO_VERSION -f ztunnel-values.yaml --wait
```

Check:

```sh
kubectl get pods -n istio-system          # istiod, istio-cni-node x N, ztunnel x N
istioctl ztunnel-config workloads         # once apps are enrolled
```

| Component | Kind | Does |
|--|--|--|
| `istiod` | Deployment | control plane; issues workload certificates, pushes config to ztunnel and waypoints |
| `istio-cni-node` | DaemonSet | sets up redirection inside each enrolled pod's network namespace |
| `ztunnel` | DaemonSet | per-node L4 proxy: mTLS, identity, L4 authorization, telemetry |

There is no ingress gateway chart here on purpose — kgateway is the ingress.

For mesh certificates from AWS Private CA (root of trust outside the cluster),
set that up first — see `../08-external-pki/`.

Docs: <https://istio.io/latest/docs/ambient/install/helm/>
