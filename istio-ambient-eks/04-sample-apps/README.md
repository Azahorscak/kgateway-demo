# Sample apps

`httpbin` is the same app as `oss/01-getting-started/sample-app/`, with its
namespace labelled for ambient. `curl` is an in-mesh client in its own
namespace, used to show east-west policy in `06-mesh-security/` and
`07-waypoint/`.

Enrolling is just the label — no restart, no injected container:

```sh
kubectl apply -f .
kubectl get pods -n httpbin        # 1/1 READY, not 2/2
istioctl ztunnel-config workloads  # httpbin and curl show PROTOCOL HBONE
```

To take a namespace out of the mesh, remove the label:
`kubectl label namespace httpbin istio.io/dataplane-mode-`.

Docs: <https://istio.io/latest/docs/ambient/usage/add-workloads/>
