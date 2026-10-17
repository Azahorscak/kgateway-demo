# kgateway as ambient ingress

Install the CRDs, then the controller with the Istio integration switched on:

```sh
export KGW_VERSION=v2.4.0

helm upgrade -i kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds \
  -n kgateway-system --create-namespace --version $KGW_VERSION

helm upgrade -i kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  -n kgateway-system --version $KGW_VERSION -f helm-values.yaml
```

Enroll the gateway's namespace in ambient **before** creating the `Gateway`,
so the proxy pod starts captured (enrolling later works too, without a
restart):

```sh
kubectl label namespace kgateway-system istio.io/dataplane-mode=ambient
kubectl apply -f gatewayparameters.yaml -f gateway.yaml
```

The proxy is now an ordinary ambient workload. It still picks endpoints and
load-balances itself; ztunnel on its node intercepts each upstream connection
and carries it over HBONE to the ztunnel on the destination node. To check:

```sh
istioctl ztunnel-config workloads | grep kgateway-system   # PROTOCOL should be HBONE
```

Do not enroll the controller in a sidecar mesh (`istio-injection=enabled`)
and ambient at the same time — pick ambient.

## Files

- `helm-values.yaml` — turns on the Istio integration in the controller
- `gatewayparameters.yaml` — `LoadBalancer` Service with AWS LB Controller annotations for an internet-facing NLB with IP targets
- `gateway.yaml` — the `http` Gateway on port 80

Docs: <https://kgateway.dev/docs/envoy/latest/integrations/istio/ambient/ambient-ingress/>
