# Policy attachment

The ways a kgateway policy finds its target, in one place:

| File | Mechanism |
|--|--|
| `targetrefs.yaml` | `targetRefs` by name — Gateway, listener (`sectionName`), or route rule (`sectionName`) |
| `extensionref.yaml` | the route names the policy via an `ExtensionRef` filter |
| `targetselectors.yaml` | `targetSelectors` by label, optionally from a global policy namespace |

Attaching via the `ExtensionRef` filter is legacy behaviour and may be
deprecated. Prefer `targetRefs.sectionName` against a named HTTPRoute rule,
which needs the Gateway API experimental channel 1.3.0 or later. Where both
apply to the same route, `ExtensionRef` wins.

When two policies hit the same target, the more specific one wins; see the
merging rules in the docs.

Docs: <https://kgateway.dev/docs/envoy/latest/about/policies/trafficpolicy/>
