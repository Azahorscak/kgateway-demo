# Install

Enterprise adds the ext auth server, the rate limit server, the WAF server, and
Redis. They are provisioned lazily: nothing is deployed for a GatewayClass until
the first `Gateway` referencing it is created.

Values names vary by release — check the Helm reference for your version.

Docs: <https://docs.solo.io/kgateway/latest/install/helm/>
