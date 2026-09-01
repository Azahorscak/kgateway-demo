# Policy attachment

The four ways a kgateway policy finds its target, in one place:

| File | Mechanism |
|--|--|
| `targetrefs.yaml` | `targetRefs` by name — Gateway, listener (`sectionName`), or route rule |
| `extensionref.yaml` | the route names the policy via an `ExtensionRef` filter |
| `targetselectors.yaml` | `targetSelectors` by label, optionally from a global policy namespace |

When two policies hit the same target, the more specific one wins; see the
merging rules in the docs.

Docs: <https://kgateway.dev/docs/envoy/latest/about/policies/>
