# Listener sets (ListenerSet)

Attach extra listeners to an existing Gateway. Routes bind to the listener set
with `parentRefs.kind: ListenerSet` (group `gateway.networking.k8s.io`).

`ListenerSet` is `gateway.networking.k8s.io/v1` and ships only in the Gateway
API **experimental** channel — install `experimental-install.yaml`. Earlier
Gateway API releases called it `XListenerSet` in the
`gateway.networking.x-k8s.io` group; that spelling is gone as of Gateway API
1.6.

The Gateway must opt in with `spec.allowedListeners`, and it still needs at
least one listener of its own even if nothing uses it.

Docs: <https://kgateway.dev/docs/envoy/latest/setup/listeners/overview/>
