# IP access control

Rules use longest-prefix matching, so the order you list them in does not
matter — the most specific CIDR always wins. That is what lets you punch a hole
in a broad rule: deny `10.0.0.0/8` and allow `10.1.0.0/16` in the same policy,
and the `/16` wins for addresses inside it.

Docs: <https://kgateway.dev/docs/envoy/latest/security/acl/>
