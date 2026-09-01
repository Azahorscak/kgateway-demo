# API key auth

An `AuthConfig` selects API key Secrets by label; the client's identity is the
Secret's name, forwarded upstream as `x-user-id`.

Keys can be stored as plaintext (above), or as HMAC or digest values so the raw
key is never in the cluster — set `apiKeyAuth.hmac` or `apiKeyAuth.digest`.
`labelSelector` sits directly under `apiKeyAuth`; the `k8sSecretApikeyStorage`
block is the older, more verbose way to say the same thing.

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/apikey/>
