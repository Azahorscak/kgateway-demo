# JWT authentication

The provider lives on a `GatewayExtension`; the `TrafficPolicy` turns it on for
a Gateway or route. `GatewayExtension.spec.jwt.validationMode` controls what
happens when no token is present: `Strict` (the default — a valid JWT is
required) or `AllowMissing` (unauthenticated requests pass through, so pair it
with an RBAC policy).

Docs: <https://kgateway.dev/docs/envoy/latest/security/jwt/simple/basic/>
