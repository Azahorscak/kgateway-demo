# Load balancing

`roundRobin`, `leastRequest`, `random`, `ringHash`, and `maglev` are set on a
`BackendConfigPolicy` that targets the Service (not the route).

Docs: <https://kgateway.dev/docs/envoy/latest/traffic-management/session-affinity/loadbalancing/>
