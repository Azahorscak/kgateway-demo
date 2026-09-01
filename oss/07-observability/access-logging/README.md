# Access logging

JSON access logs to stdout. `%RESPONSE_FLAGS%` is the field worth keeping — it
is how you tell a backend 5xx apart from a gateway-side failure.

Docs: <https://kgateway.dev/docs/envoy/latest/security/access-logging/>
