# Solo Enterprise for kgateway

Everything in `oss/` still applies — the enterprise distribution is a superset.
What it adds is the pieces OSS expects you to supply yourself:

| Directory | Adds |
|--|--|
| `01-install/` | Helm values with a license key; `EnterpriseKgatewayParameters` |
| `02-ext-auth/` | a managed ext auth server: basic, API key, OIDC, OAuth2, OPA, passthrough |
| `03-rate-limiting/` | a managed rate limit server with Redis-backed global counters |
| `04-waf/` | Coraza WAF with the OWASP Core Rule Set |
| `05-portal/` | developer portal |

## One difference from `oss/` before you copy anything

The enterprise install creates its own GatewayClasses — `enterprise-kgateway`
and `enterprise-kgateway-waypoint`, both on controller
`solo.io/enterprise-kgateway`. The OSS `kgateway` class is not what you want
here. Every Gateway in `oss/` sets `gatewayClassName: kgateway`; change that to
`enterprise-kgateway` when you run those examples against an enterprise
install.

## The one thing to understand

`EnterpriseKgatewayTrafficPolicy` (`enterprisekgateway.solo.io/v1alpha1`) is a
superset of the OSS `TrafficPolicy`. Every OSS field is available on it, and
enterprise features are added under `ent`-prefixed fields:

| Field | Meaning |
|--|--|
| `entExtAuth.authConfigRef` | use the built-in auth server with an `AuthConfig` |
| `entExtAuth.disable` | turn ext auth off for one route under a broader policy |
| `extAuth.extensionRef` | (OSS field) use your own auth server via a `GatewayExtension` |
| `entRateLimit.global.rateLimitConfigRefs` | use the built-in rate limit server with a `RateLimitConfig` |
| `rateLimit.local` | (OSS field) per-replica token bucket |
| `entWAF.wafPolicyRef` | apply a `WAFPolicy` |
| `entWAF.disable` | turn WAF off for one route under a gateway-wide policy |
| `entJWT` / `entRBAC` | staged JWT providers and claim-based RBAC |
| `entTransformation` | staged and AWS Lambda transformations |

Not every enterprise auth method goes through an `AuthConfig` any more. Basic
auth, API key auth and OAuth2 are also first-class fields on the policy
(`basicAuth`, `apiKeyAuth`, `oauth2`) and OSS `TrafficPolicy` has them too. The
`AuthConfig` path is what you want when the auth logic should be owned and
reviewed separately from the routing, or when you need an option only the
Gloo-lineage `AuthConfig` API exposes.

The supporting resources are separate CRDs:

| Resource | Group |
|--|--|
| `AuthConfig` | `extauth.solo.io/v1` |
| `RateLimitConfig` | `ratelimit.solo.io/v1alpha1` |
| `WAFPolicy` | `waf.solo.io/v1alpha1` |
| `EnterpriseKgatewayTrafficPolicy`, `EnterpriseKgatewayParameters` | `enterprisekgateway.solo.io/v1alpha1` |
| `Portal`, `ApiProduct`, `ApiDoc`, `PortalParameters` | `portal.solo.io/v1alpha1` |

`AuthConfig` and `RateLimitConfig` keep the Gloo Edge schemas — the enterprise
API reference links straight to the Gloo Edge proto docs for their fields, so
that is where to look when a field is not in the Solo API reference.

The ext auth (`ext-auth-service`), rate limit (`rate-limiter`) and Redis
(`ext-cache`) deployments are created per GatewayClass, and only once the first
`Gateway` for that class exists — so a fresh install looks like nothing happened
until you create a Gateway. The WAF server (`waf-server`) is opt-in; see
`04-waf/`.

Checked against the Solo Enterprise for kgateway 2.3.x docs and the published
`enterprise-kgateway` 2.3.2 Helm chart. Enterprise requires a license key from
Solo.

API reference: <https://docs.solo.io/kgateway/latest/reference/api/solo/>
