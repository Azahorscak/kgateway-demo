# Basic auth

Basic auth does not use an `AuthConfig`. It is a field on the policy itself
(`spec.basicAuth`), evaluated in the gateway, with users given inline or in a
Secret. Exactly one of `users`, `secretRef` or `disable` may be set.

The `AuthConfig` + `entExtAuth.authConfigRef` pattern that the other examples in
this directory use is for the auth methods that run in the ext auth server —
API key, OAuth2/OIDC, OPA.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/basic/>
