# Install

Two charts, both from `oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/`:
`enterprise-kgateway-crds` first, then `enterprise-kgateway`. Install into
`kgateway-system`. A license key is required — `licensing.licenseKey`, or
`licensing.secretName` if you create the Secret yourself.

Installing the control plane creates the `enterprise-kgateway` and
`enterprise-kgateway-waypoint` GatewayClasses.

The ext auth server, rate limit server, Redis (`ext-cache`) and WAF server are
not Helm values. They are *shared extensions* configured on an
`EnterpriseKgatewayParameters` resource, and they are provisioned lazily:
nothing is deployed for a GatewayClass until the first `Gateway` referencing it
is created. Redis appears once ext auth or rate limiting does.

Docs: <https://docs.solo.io/kgateway/latest/install/helm/>
