# Passthrough auth

Delegate the decision to your own server, which implements the Envoy ext_authz
gRPC protocol (an HTTP server works too — see the `http` page in the docs).

Note the field is `extAuth` (the OSS field, pointing at a `GatewayExtension`),
not `entExtAuth` — `EnterpriseKgatewayTrafficPolicy` is a superset, so both are
available on it. `extAuth` takes exactly one of `extensionRef` or `disable`;
`failOpen: true` on the GatewayExtension lets traffic through when your server
is unreachable.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/passthrough/grpc/>
