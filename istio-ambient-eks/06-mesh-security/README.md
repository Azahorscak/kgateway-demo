# Mesh security

Two policies, both enforced by ztunnel at L4 — no waypoint needed:

- `peerauthentication.yaml` — mesh-wide STRICT mTLS. Plaintext connections to
  enrolled pods from outside the mesh are refused.
- `authorizationpolicy-l4.yaml` — httpbin only accepts connections whose mTLS
  identity is the kgateway proxy. The in-mesh `curl` client is turned away.

```sh
kubectl apply -f .

# through the gateway: 200
curl -s -o /dev/null -w '%{http_code}\n' http://$LB/get -H 'host: www.example.com'

# straight from curl, bypassing the gateway: connection reset by ztunnel
kubectl exec -n curl deploy/curl -- curl -sS httpbin.httpbin:8000/get
```

This is the main reason to put the ingress gateway in the mesh: without the
`istio.io/dataplane-mode=ambient` label on `kgateway-system`, the gateway
connects in plaintext, has no identity, and STRICT mode would block it.

ztunnel can only enforce L4 attributes (source identity, namespace, IP,
destination port). A policy that mentions paths, methods or headers needs the
waypoint in `07-waypoint/`; without one, ztunnel treats such an `ALLOW` rule as
matching nothing.

Docs: <https://istio.io/latest/docs/ambient/usage/l4-policy/>
