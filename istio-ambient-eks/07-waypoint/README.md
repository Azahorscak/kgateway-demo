# Waypoint for L7 policy

ztunnel only sees connections. For anything at L7 — paths, methods, headers,
retries, HTTP metrics — a namespace or service gets a *waypoint*: an Envoy
proxy that Istio deploys from a `Gateway` with `gatewayClassName: istio-waypoint`.

```sh
kubectl apply -f .
```

What each file does:

- `waypoint.yaml` — the waypoint for the `httpbin` namespace, plus the
  namespace label `istio.io/use-waypoint: waypoint` that sends service traffic
  through it.
- `authorizationpolicy-l7.yaml` — replaces the L4 policy from
  `06-mesh-security/`. It is bound to the httpbin Service with `targetRefs`, so
  the waypoint enforces it: the gateway may only `GET`, and the `curl` client
  may only call `/headers`.
- `httpbin-service-ingress-waypoint.yaml` — see below.

```sh
kubectl delete -f ../06-mesh-security/authorizationpolicy-l4.yaml

curl -s -o /dev/null -w '%{http_code}\n' http://$LB/get -H 'host: www.example.com'           # 200
curl -s -o /dev/null -w '%{http_code}\n' -X POST http://$LB/post -H 'host: www.example.com'  # 403
kubectl exec -n curl deploy/curl -- curl -s -o /dev/null -w '%{http_code}\n' httpbin.httpbin:8000/headers  # 200
kubectl exec -n curl deploy/curl -- curl -s -o /dev/null -w '%{http_code}\n' httpbin.httpbin:8000/get      # 403
```

## Ingress traffic and the waypoint

kgateway picks a pod and connects to its IP, not the Service VIP. A waypoint
bound to services (the default, `istio.io/waypoint-for: service`) only sees
traffic addressed to the Service, so by default the hop from kgateway to
httpbin **skips the waypoint** — and the 403 above would not happen.

Labelling the Service `istio.io/ingress-use-waypoint: "true"` tells kgateway
(with `KGW_ENABLE_ISTIO_INTEGRATION=true`, see `03-kgateway/`) to send that
Service's traffic to the waypoint instead of directly to the pods, so ingress
gets the same L7 policy as east-west traffic.

## Why not a kgateway waypoint

kgateway used to offer `gatewayClassName: kgateway-waypoint`, which let you
attach `TrafficPolicy` to east-west traffic. It is deprecated in kgateway OSS.
Solo Enterprise for kgateway still ships `enterprise-kgateway-waypoint` if you
want that.

Docs:

- <https://istio.io/latest/docs/ambient/usage/waypoint/>
- <https://istio.io/latest/docs/ambient/usage/l7-features/>
