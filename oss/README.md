# kgateway (open source)

| Directory | Covers |
|--|--|
| `01-getting-started/` | GatewayClass, sample app, first Gateway and HTTPRoute |
| `02-listeners/` | HTTPS, SNI, mTLS, TCP, TLS passthrough, listener sets |
| `03-traffic-management/` | matching, splits, redirects, rewrites, headers, transformations, delegation, ext proc, CORS |
| `04-backends/` | static hosts, AWS Lambda, dynamic forward proxy, backend TLS, priority failover |
| `05-resiliency/` | retries, timeouts, circuit breakers, outlier detection, health checks, fault injection, mirroring |
| `06-security/` | JWT, RBAC, external auth, rate limiting, IP ACLs, CSRF |
| `07-observability/` | access logging, OpenTelemetry tracing |
| `08-gateway-config/` | GatewayParameters, autoscaling, zone-aware routing, policy attachment |

## Two things worth knowing before you read the rest

**Which policy kind to reach for** is decided by what you are attaching to, not
by what the policy does:

- targeting a route or a Gateway → `TrafficPolicy`
- targeting a listener → `ListenerPolicy`
- targeting a backend (Service or `Backend`) → `BackendConfigPolicy`

That is why retries live on a `TrafficPolicy` but circuit breakers live on a
`BackendConfigPolicy` — a retry is a property of a request, a circuit breaker is
a property of a connection pool.

**Some features have both a Gateway API form and a kgateway form** — CORS,
retries, timeouts, and header modification among them. Prefer the Gateway API
form for portability; reach for the kgateway policy when you need something the
standard does not express (`retryOn` conditions, reuse across many routes,
attachment by label). Do not configure both on the same route.

Docs: <https://kgateway.dev/docs/envoy/latest/>
