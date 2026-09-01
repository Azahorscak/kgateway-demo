# OWASP Core Rule Set

WAF runs in its own `waf-server` deployment, which is off by default. Turn it on
first with `sharedExtensions.waf.enabled: true` on the
`EnterpriseKgatewayParameters` that your GatewayClass points at — see
`../../01-install/enterprise-gateway-parameters/`.

Run CRS in detection mode first (`SecRuleEngine DetectionOnly` in
`ruleEngineSettings`) and read the logs before switching to `On` — the default
rule set will block real traffic.

The WAF server fails closed: a `WAFPolicy` whose directives do not compile makes
every matching request 500 until you fix it. Check the WAFPolicy status.

Docs: <https://docs.solo.io/kgateway/latest/security/waf/owasp-crs/>
