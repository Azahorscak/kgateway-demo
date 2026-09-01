# Global rate limiting

A limit shared across every gateway replica, enforced by an external rate limit
service. OSS kgateway does not ship that service — bring your own, or use Solo
Enterprise (`enterprise/03-rate-limiting/`).

Docs: <https://kgateway.dev/docs/envoy/latest/security/ratelimit/global/>
