# Disable WAF for one route

`entWAF` takes exactly one of `wafPolicyRef` or `disable`, so a route-level
policy with `disable: {}` is how you exempt a route from a gateway-wide WAF.

Docs: <https://docs.solo.io/kgateway/latest/security/waf/overview/>
