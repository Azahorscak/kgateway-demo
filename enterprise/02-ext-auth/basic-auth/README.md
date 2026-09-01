# Basic auth

Two resources, and this pattern repeats for every ext auth example here: an
`AuthConfig` holds the auth logic, and an `EnterpriseKgatewayTrafficPolicy`
attaches it to a Gateway or route via `entExtAuth.authConfigRef`.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/basic/>
