# Solo Enterprise for kgateway

Everything in `oss/` still applies — the enterprise distribution is a superset.
What it adds is the pieces OSS expects you to supply yourself:

| Directory | Adds |
|--|--|
| `01-install/` | Helm values with a license key; `EnterpriseKgatewayParameters` |
| `02-ext-auth/` | a managed ext auth server: basic, API key, OIDC, OAuth2, OPA, passthrough |
| `03-rate-limiting/` | a managed rate limit server with Redis-backed global counters |
| `04-waf/` | Coraza WAF with the OWASP Core Rule Set |
| `05-portal/` | developer portal (see the note in that directory) |

## The one thing to understand

`EnterpriseKgatewayTrafficPolicy` (`enterprisekgateway.solo.io/v1alpha1`) is a
superset of the OSS `TrafficPolicy`. Every OSS field is available on it, and
enterprise features are added under `ent`-prefixed fields:

| Field | Meaning |
|--|--|
| `entExtAuth.authConfigRef` | use the built-in auth server with an `AuthConfig` |
| `extAuth.extensionRef` | (OSS field) use your own auth server via a `GatewayExtension` |
| `entRateLimit.global.rateLimitConfigRefs` | use the built-in rate limit server with a `RateLimitConfig` |
| `rateLimit.local` | (OSS field) per-replica token bucket |
| `entWAF.wafPolicyRef` | apply a `WAFPolicy` |
| `entWAF.disable` | turn WAF off for one route under a gateway-wide policy |

The supporting resources are separate CRDs, so the auth/limit/WAF logic can be
owned and reviewed independently of the routing:

| Resource | Group |
|--|--|
| `AuthConfig` | `extauth.solo.io/v1` |
| `RateLimitConfig` | `ratelimit.solo.io/v1alpha1` |
| `WAFPolicy` | `waf.solo.io/v1alpha1` |
| `EnterpriseKgatewayTrafficPolicy`, `EnterpriseKgatewayParameters` | `enterprisekgateway.solo.io/v1alpha1` |

The ext auth, rate limit, and WAF servers are deployed per GatewayClass, and
only once the first `Gateway` for that class exists — so a fresh install looks
like nothing happened until you create a Gateway.

## Accuracy note

`docs.solo.io` was not reachable from the environment that generated this repo,
so unlike `oss/` — which was written against the kgateway documentation source —
these manifests were assembled from search results and the shape of the
long-standing Solo APIs they descend from. The resource kinds, API groups, and
top-level fields above are the parts to trust least. Verify against the API
reference for your version before relying on them:

<https://docs.solo.io/kgateway/latest/reference/api/solo/>

Enterprise requires a license key from Solo.
