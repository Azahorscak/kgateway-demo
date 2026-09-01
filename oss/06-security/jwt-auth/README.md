# JWT authentication

The provider lives on a `GatewayExtension`; the `TrafficPolicy` turns it on for
a Gateway or route. `spec.jwt.validationMode` (`Strict`, `AllowMissing`,
`AllowMissingOrFailed`) controls what happens when no token is present.

Docs: <https://kgateway.dev/docs/envoy/latest/security/jwt/>
