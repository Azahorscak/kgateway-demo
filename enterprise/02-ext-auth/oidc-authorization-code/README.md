# OIDC authorization code flow

Browser login at the gateway. `appUrl` + `callbackPath` must be registered as a
valid redirect URI with the identity provider, and the callback path needs a
route that this policy actually applies to — a `/` prefix route is enough — or
the callback never reaches the ext auth filter.

`issuerUrl` is used for OIDC discovery, so it must serve
`.well-known/openid-configuration`.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/oauth/authorization-code/>
