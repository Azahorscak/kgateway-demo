# Istio ambient mesh on EKS, with kgateway for ingress

An end-to-end walkthrough: an EKS cluster, Istio in ambient mode (no sidecars),
kgateway as the north-south entry point behind an AWS NLB, and mesh policy
enforced on the traffic between them.

```
              internet
                 │
          AWS NLB (ip targets)
                 │
   ┌─────────────▼──────────────┐   kgateway-system  (istio.io/dataplane-mode=ambient)
   │  kgateway Envoy  "http"     │
   └─────────────┬──────────────┘
                 │  HBONE / mTLS (ztunnel → ztunnel, port 15008)
   ┌─────────────▼──────────────┐   httpbin  (istio.io/dataplane-mode=ambient)
   │  [waypoint]  →  httpbin     │
   └────────────────────────────┘
```

kgateway terminates the client connection and does L7 routing. Because its own
namespace is enrolled in ambient, ztunnel picks up the gateway's upstream
connections and wraps them in mTLS, so the backend sees a SPIFFE identity for
the gateway (`cluster.local/ns/kgateway-system/sa/http`) that you can write
`AuthorizationPolicy` against. No sidecar is injected anywhere.

| Directory | Covers |
|--|--|
| `01-eks-cluster/` | eksctl cluster config and the EKS-specific prerequisites |
| `02-istio-ambient/` | Helm values for base, istiod, istio-cni and ztunnel (ambient profile) |
| `03-kgateway/` | kgateway Helm values, NLB-backed `GatewayParameters`, the ingress `Gateway` |
| `04-sample-apps/` | httpbin and a curl client in ambient-enrolled namespaces |
| `05-ingress/` | the `HTTPRoute` from kgateway to httpbin |
| `06-mesh-security/` | STRICT mTLS and an L4 `AuthorizationPolicy` that only lets the gateway in |
| `07-waypoint/` | an Istio waypoint for L7 policy, and making ingress traffic use it |
| `08-external-pki/` | mesh certificates from AWS Private CA with the root of trust outside the cluster: plug-in CA, and istio-csr |

## Order of operations

Each step's README has the commands. In short:

```sh
# 1. cluster
eksctl create cluster -f 01-eks-cluster/cluster.yaml

# 2. Gateway API CRDs (both Istio and kgateway need them)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# 3. Istio ambient — see 02-istio-ambient/README.md for the four helm installs
#    (for a root of trust outside the cluster, do 08-external-pki/ first:
#    it changes how istiod and ztunnel are installed)

# 4. kgateway — see 03-kgateway/README.md
kubectl label namespace kgateway-system istio.io/dataplane-mode=ambient
kubectl apply -f 03-kgateway/

# 5. apps and route
kubectl apply -f 04-sample-apps/
kubectl apply -f 05-ingress/

# 6. lock it down
kubectl apply -f 06-mesh-security/

# 7. optional L7 in the mesh
kubectl apply -f 07-waypoint/
```

Then:

```sh
export LB=$(kubectl get svc http -n kgateway-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -i http://$LB/headers -H 'host: www.example.com'
```

## How this relates to the rest of the repo

Names line up with `oss/`: the gateway is `http` in `kgateway-system` and the
backend is `httpbin` on port 8000 in the `httpbin` namespace. Every example in
`oss/` still works on top of this setup — the mesh sits underneath the
gateway, it does not change how you configure the gateway.

## Versions

Written against Istio 1.27.x, kgateway 2.4.x and EKS 1.33. Ambient has been GA
since Istio 1.24; earlier versions use different Helm values.

The kgateway-as-waypoint integration (`gatewayClassName: kgateway-waypoint`) is
deprecated in kgateway and is not used here — `07-waypoint/` uses Istio's own
waypoint. For a supported Envoy-based waypoint with kgateway policy, see
Solo Enterprise for kgateway (`enterprise-kgateway-waypoint` GatewayClass).

Docs:

- <https://kgateway.dev/docs/envoy/latest/integrations/istio/ambient/ambient-ingress/>
- <https://istio.io/latest/docs/ambient/install/helm/>
- <https://istio.io/latest/docs/ambient/install/platform-prerequisites/#amazon-elastic-kubernetes-service-eks>
