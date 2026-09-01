# Custom Coraza rules

`customDirectives` entries take either an `inline` string or a `configMap`
reference, and are applied after `ruleEngineSettings` and any CRS rules. The
ConfigMap form is worth it for anything non-trivial — the WAF server watches the
ConfigMap and reloads rules without a policy change.

Custom rule IDs must not collide with CRS, which uses the 9xxxxx range.

Docs: <https://docs.solo.io/kgateway/latest/security/waf/custom-rules/>
