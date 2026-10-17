# TCP keepalive

A test app and a repeatable demo that proves kgateway's TCP keepalives are
actually on the wire and actually detect dead peers — on both sides of the proxy.

```
tcp-client ──(downstream)──> Gateway tcp-keepalive :9000 ──(upstream)──> tcp-server :9000
             ListenerPolicy                              BackendConfigPolicy
             default.tcpKeepalive                        tcpKeepalive
```

| File | What it is |
|--|--|
| `app.yaml` | namespace `keepalive-demo`, Python echo server + idle client (ConfigMap), netshoot sidecars |
| `gateway.yaml` | `Gateway` with a TCP listener on 9000 and a `TCPRoute` to `tcp-server` |
| `backendconfigpolicy.yaml` | upstream keepalive: 10s idle, 5s interval, 3 probes |
| `listenerpolicy.yaml` | downstream keepalive, same values (kgateway 2.3+) |
| `test.sh` | automated black-hole test, prints PASS/FAIL |

The short values put the detection budget at
`keepAliveTime + keepAliveProbes × keepAliveInterval = 10 + 3×5 = 25s`.
Production values are usually minutes; they only need to be shorter than the
idle timeout of whatever sits in the path (NAT, cloud LB, firewall conntrack).

The client and server never enable `SO_KEEPALIVE` themselves, so every probe
you see comes from Envoy. A TCP listener is used on purpose: no HTTP idle
timeout gets in the way, and the TCP proxy's own idle timeout is 1h.

Docs: <https://kgateway.dev/docs/envoy/latest/resiliency/connection/>

## Prerequisites

- kgateway 2.3+ installed (`gatewayClassName: kgateway`). The upstream half
  works on older versions; `ListenerPolicy.tcpKeepalive` arrived in 2.3.
- The cluster must allow `NET_ADMIN`/`NET_RAW` on the netshoot sidecars
  (kind, k3d, minikube are fine; restricted Pod Security will reject it).

```sh
kubectl apply -f app.yaml -f gateway.yaml
kubectl -n keepalive-demo rollout status deploy/tcp-server deploy/tcp-client deploy/tcp-keepalive
```

## Automated test

```sh
./test.sh                  # ~4 min: baseline, upstream, downstream
SKIP_BASELINE=1 ./test.sh  # ~1.5 min
```

How it works: open an idle connection through the gateway, then `iptables
DROP` all TCP inside one pod. Nothing sends a FIN or RST, so the only way the
gateway can find out is keepalive probes going unanswered.

| Scenario | Policies | Black-holed | Pass when |
|--|--|--|--|
| baseline | none | server, then client | connection still open after `MAX_WAIT` (60s) |
| upstream | `BackendConfigPolicy` | `tcp-server` | client sees the gateway close it in 18–40s |
| downstream | + `ListenerPolicy` | `tcp-client` | server sees the gateway close it in 18–40s |

The baseline is the control: it shows the closes in the other two scenarios
are caused by the policies and nothing else. Tunables: `MAX_WAIT`, `LOW`,
`HIGH`, `SETTLE` (env vars).

## Manual walkthrough

### 1. Apply the policies and check status

```sh
kubectl apply -f backendconfigpolicy.yaml -f listenerpolicy.yaml
kubectl -n keepalive-demo get backendconfigpolicy upstream-keepalive -o jsonpath='{.status}' | jq
kubectl -n keepalive-demo get listenerpolicy downstream-keepalive -o jsonpath='{.status}' | jq
```

Both should report `Accepted` / `Attached`.

### 2. Check the Envoy config

```sh
kubectl -n keepalive-demo port-forward deploy/tcp-keepalive 19000 &
curl -s localhost:19000/config_dump | jq '..|.tcp_keepalive? // empty'
```

Expect two hits — one from the cluster's `upstream_connection_options`, one
from the listener:

```json
{ "keepalive_probes": 3, "keepalive_time": 10, "keepalive_interval": 5 }
```

### 3. Open an idle connection

```sh
kubectl -n keepalive-demo exec -it deploy/tcp-client -c client -- \
  python /app/client.py --id manual --max-wait 600
```

Leave it running. In another terminal, follow the server:

```sh
kubectl -n keepalive-demo logs -f deploy/tcp-server -c server
```

### 4. See the keepalive timers on the gateway's sockets

The proxy image has no shell, so attach an ephemeral container (it shares the
pod's network namespace):

```sh
POD=$(kubectl -n keepalive-demo get pod -l gateway.networking.k8s.io/gateway-name=tcp-keepalive -o name)
kubectl -n keepalive-demo debug -it "$POD" --image=nicolaka/netshoot:v0.13 -- ss -tno state established
```

Both the accepted socket (local `:9000`, from the client) and the upstream
socket (peer `:9000`, to `tcp-server`) should show a keepalive timer counting
down from 10s:

```
... timer:(keepalive,7.412sec,0)
```

Without the policies there is no `timer:` field on idle sockets.

### 5. Watch the probes on the wire

Upstream probes arrive at the server; downstream probes arrive at the client:

```sh
kubectl -n keepalive-demo exec -it deploy/tcp-server -c netshoot -- tcpdump -ni eth0 tcp port 9000
kubectl -n keepalive-demo exec -it deploy/tcp-client -c netshoot -- tcpdump -ni eth0 tcp port 9000
```

Every 10s of idle you get a zero-length segment from the gateway, with a
sequence number one behind (`seq N-1`, `length 0`), and the kernel's ACK in
reply. Nothing at all in the application logs — probes are invisible to the
app.

### 6. Kill a peer silently

Black-hole the server:

```sh
kubectl -n keepalive-demo exec deploy/tcp-server -c netshoot -- \
  sh -c 'iptables -I INPUT -p tcp -j DROP; iptables -I OUTPUT -p tcp -j DROP'
```

The `tcpdump` on the server shows the probes arriving 5s apart with no reply.
About 25s after the last traffic, the client prints:

```
CLOSED id=manual after=25.0s reason=eof
```

Undo with `iptables -D` (same rules), then repeat against `tcp-client` to test
the downstream side — that time it is the server log that shows
`CLOSE id=... duration=25.0s`.

## Troubleshooting

- **Closed in ~25s in the baseline** — a leftover policy, or a GatewayParameters
  / Helm value that sets socket options globally. Check `config_dump` for
  `tcp_keepalive`.
- **Never closes with the policies applied** — policy not attached (`status`),
  or the connection was opened before the policy reached Envoy: socket options
  apply when a connection is created, existing ones keep their old settings.
- **Closes much later than 25s** — the iptables rule went in after the first
  probe had already been answered, which restarts the count. Apply it within
  10s of connecting (the script does).
- **`iptables` fails** — the sidecar did not get `NET_ADMIN`; check Pod
  Security admission on the namespace.

## Cleanup

```sh
kubectl delete ns keepalive-demo
```
