# EnterpriseKgatewayParameters

Configures the shared enterprise services — ext auth, rate limiter, Redis
(`extCache`) and WAF — for a GatewayClass, under
`spec.kube.sharedExtensions`. Each entry takes the usual deployment knobs
(`enabled`, `replicas`, `resources`, `pod`, overlays, HPA/PDB/VPA).

`spec.kube` also inherits every OSS `GatewayParameters` field, so this one
resource shapes both the Envoy proxy deployment and the extension deployments.

Attach it from the GatewayClass with `spec.parametersRef`, or set the Helm value
`gatewayClassParametersRefs` so the install wires it up for you.

Docs: <https://docs.solo.io/kgateway/latest/setup/customize/>
