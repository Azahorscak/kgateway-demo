# Priority groups (failover)

A `Backend` composed of ordered `priorityGroups`. Traffic goes to group 0 and
fails over to group 1 only when group 0 has no healthy endpoints, so an active
health check is required.

Docs: <https://kgateway.dev/docs/envoy/latest/traffic-management/destination-types/backends/priority-groups/>
