# Ingress route

A plain `HTTPRoute` — nothing about it is mesh-aware. The mesh is invisible to
the route; it only changes how the gateway's upstream connection travels.

```sh
kubectl apply -f httproute.yaml

export LB=$(kubectl get svc http -n kgateway-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -i http://$LB/headers -H 'host: www.example.com'
```

The NLB can take a couple of minutes to pass health checks after it is created.

To see that the hop from gateway to httpbin went over mTLS, look at ztunnel's
access log on the httpbin pod's node:

```sh
kubectl logs -n istio-system -l app=ztunnel --tail=20 | grep httpbin
# ... src.identity="spiffe://cluster.local/ns/kgateway-system/sa/http"
#     dst.identity="spiffe://cluster.local/ns/httpbin/sa/httpbin" ...
```

Docs: <https://kgateway.dev/docs/envoy/latest/integrations/istio/ambient/ambient-ingress/>
