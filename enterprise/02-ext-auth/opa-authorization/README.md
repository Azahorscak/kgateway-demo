# OPA authorization

Chain this after an authentication step (JWT or OIDC) by listing both entries in
one AuthConfig's `configs`. They run in list order and, by default, all must
pass. Give each config a `name` and set `booleanExpr` on the AuthConfig
(`jwt && opa`, `passthrough || basic`, ...) when you want anything other than
AND.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/opa/rego-cm/>
