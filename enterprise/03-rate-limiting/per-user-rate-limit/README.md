# Per-user rate limiting

Pairs well with ext auth: have the auth step set `x-user-id`, then key the limit
on it so one noisy tenant cannot spend everyone else's budget.

Docs: <https://docs.solo.io/kgateway/latest/security/ratelimit/global/envoy/>
