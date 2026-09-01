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
| `XListenerSet` | `gateway.networking.x-k8s.io` | add listeners to a Gateway you do not own |
| `TrafficPolicy` | `gateway.kgateway.dev` | per-route/gateway policy: transformations, rate limit, auth, CORS, retries |
| `ListenerPolicy` | `gateway.kgateway.dev` | per-listener policy: access logs, tracing, timeouts, header handling |
| `BackendConfigPolicy` | `gateway.kgateway.dev` | per-backend policy: load balancing, health checks, circuit breakers |
| `Backend` | `gateway.kgateway.dev` | destinations that are not Kubernetes Services (static, AWS Lambda, DFP) |
| `GatewayExtension` | `gateway.kgateway.dev` | pointer to an external service: ext auth, rate limit, ext proc, JWT providers |
| `GatewayParameters` | `gateway.kgateway.dev` | how the Envoy proxy deployment itself is built |
| `DirectResponse` | `gateway.kgateway.dev` | answer at the gateway with a fixed status and body |

`ListenerPolicy` was called `HTTPListenerPolicy` before kgateway 2.2.

## Versions

Written against kgateway 2.x (`latest` docs) and Solo Enterprise for kgateway
2.x. Field names do move between minor versions — check the API reference for
the version you run:

- OSS: <https://kgateway.dev/docs/envoy/latest/reference/api/>
- Enterprise: <https://docs.solo.io/kgateway/latest/>

## AI / agent workloads

Not covered here. kgateway's AI gateway, MCP, and LLM routing moved to the
separate [agentgateway](https://agentgateway.dev/docs) project, which kgateway
can drive as a data plane via `gatewayClassName: agentgateway`.
