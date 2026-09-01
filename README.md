# kgateway demo files

Static YAML examples for [kgateway](https://kgateway.dev), split into what the
open source project gives you and what Solo's enterprise distribution adds on
top.

```
oss/          kgateway (open source, Apache 2.0)
enterprise/   Solo Enterprise for kgateway
```

Every distinct example is its own subdirectory with the manifests and a short
README pointing at the upstream docs page it came from. Nothing here is a
runnable script or a Helm chart — these are reference manifests meant to be read,
copied, and adapted.

## How to use this

The examples assume a cluster with kgateway installed into `kgateway-system` and
the sample app from `oss/01-getting-started/sample-app/` deployed. From there,
each example is self-contained:

```sh
kubectl apply -f oss/01-getting-started/sample-app/
kubectl apply -f oss/01-getting-started/http-gateway/
kubectl apply -f oss/05-resiliency/retries/trafficpolicy.yaml
```

Names, ports, and hostnames are consistent across examples: the gateway is
`http` in `kgateway-system`, and the backend is the `httpbin` Service on port
8000 in the `httpbin` namespace.

## The resources you will see

| Resource | Group | What it does |
|--|--|--|
| `Gateway`, `HTTPRoute`, `TCPRoute`, `TLSRoute` | `gateway.networking.k8s.io` | Kubernetes Gateway API: listeners and routing |
| `ListenerSet` | `gateway.networking.k8s.io` | add listeners to a Gateway you do not own (experimental channel) |
| `TrafficPolicy` | `gateway.kgateway.dev` | per-route/gateway policy: transformations, rate limit, auth, CORS, retries |
| `ListenerPolicy` | `gateway.kgateway.dev` | per-listener policy: access logs, tracing, timeouts, header handling |
| `BackendConfigPolicy` | `gateway.kgateway.dev` | per-backend policy: load balancing, health checks, circuit breakers |
| `Backend` | `gateway.kgateway.dev` | destinations that are not Kubernetes Services (static, AWS Lambda, DFP) |
| `GatewayExtension` | `gateway.kgateway.dev` | pointer to an external service: ext auth, rate limit, ext proc, JWT providers |
| `GatewayParameters` | `gateway.kgateway.dev` | how the Envoy proxy deployment itself is built |
| `DirectResponse` | `gateway.kgateway.dev` | answer at the gateway with a fixed status and body |

`ListenerPolicy` arrived in kgateway 2.2. The older `HTTPListenerPolicy` still
exists and still works, but it is deprecated — everything it configured now lives
under `ListenerPolicy`'s `default.httpSettings` (or `perPort[].listener.httpSettings`),
and `ListenerPolicy` also covers the non-HTTP listener settings.

## Versions

Checked against the kgateway `latest` docs (2.4.x) and the Solo Enterprise for
kgateway `latest` docs (2.3.x). Field names do move between minor versions —
check the API reference for the version you actually run:

- OSS: <https://kgateway.dev/docs/envoy/latest/reference/api/>
- Enterprise: <https://docs.solo.io/kgateway/latest/reference/api/solo/>

Two deprecations to know about at 2.4.x: `GatewayExtension.spec.type` and
`Backend.spec.type` are ignored — the kind is inferred from whichever config
block you set. The examples here still set them, because they read better and
older versions require them.

## AI / agent workloads

Not covered here. kgateway's AI gateway, MCP, and LLM routing moved to the
separate [agentgateway](https://agentgateway.dev/docs/kubernetes/latest/) project,
which has its own control plane and GatewayClass (`gatewayClassName: agentgateway`).
