# Route delegation

Multi-tenant routing: a parent HTTPRoute hands a path prefix to child routes in
a team namespace. The child inherits the parent's hostname and cannot route
outside the delegated prefix.

Docs: <https://kgateway.dev/docs/envoy/latest/traffic-management/route-delegation/>
