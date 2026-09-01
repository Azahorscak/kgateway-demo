# Passthrough auth

Note the field is `extAuth` (the OSS field, pointing at a `GatewayExtension`),
not `entExtAuth` — `EnterpriseKgatewayTrafficPolicy` is a superset, so both are
available on it.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/passthrough/>
