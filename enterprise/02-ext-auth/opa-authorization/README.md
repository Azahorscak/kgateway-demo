# OPA authorization

Chain this after an authentication step (JWT or OIDC) by listing both entries in
one AuthConfig's `configs` — they run in order and all must pass.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/>
