#!/usr/bin/env bash
# Black-hole test for kgateway TCP keepalives.
#
# Each scenario opens an idle connection through the gateway, then silently
# drops all TCP in one pod (no FIN, no RST). Only keepalive probes can notice.
#
#   baseline   no policies          -> dead peer is NOT detected within MAX_WAIT
#   upstream   BackendConfigPolicy  -> server black-holed, client is closed in ~25s
#   downstream ListenerPolicy       -> client black-holed, server is closed in ~25s
#
# Prereqs: kgateway installed, `kubectl apply -f app.yaml -f gateway.yaml`.
# Usage:   ./test.sh            (SKIP_BASELINE=1 to save ~2 minutes)
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
NS=keepalive-demo
GW=tcp-keepalive
MAX_WAIT=${MAX_WAIT:-60}   # how long to wait for a close before calling it "not detected"
LOW=${LOW:-18}             # expected detection window, policy budget is 25s
HIGH=${HIGH:-40}
SETTLE=${SETTLE:-10}       # time for xDS to reach Envoy after a policy change
SKIP_BASELINE=${SKIP_BASELINE:-0}

TMP=$(mktemp -d)
FAILED=0
k() { kubectl -n "$NS" "$@"; }
log() { printf '\n=== %s\n' "$*"; }
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
in_range() { awk -v d="$1" -v lo="$LOW" -v hi="$HIGH" 'BEGIN { exit !(d >= lo && d <= hi) }'; }

blackhole() { k exec "deploy/$1" -c netshoot -- sh -c 'iptables -I INPUT -p tcp -j DROP && iptables -I OUTPUT -p tcp -j DROP'; }
restore()   { k exec "deploy/$1" -c netshoot -- sh -c 'iptables -D INPUT -p tcp -j DROP; iptables -D OUTPUT -p tcp -j DROP' >/dev/null 2>&1 || true; }
cleanup()   { restore tcp-server; restore tcp-client; rm -rf "$TMP"; }
trap cleanup EXIT

# Starts an idle client connection in the background; sets CLIENT_PID.
start_client() {
  local id=$1
  k exec deploy/tcp-client -c client -- \
    python -u /app/client.py --host "$GW.$NS.svc.cluster.local" --id "$id" --max-wait "$MAX_WAIT" \
    >"$TMP/$id.log" 2>&1 &
  CLIENT_PID=$!
  for _ in $(seq 20); do
    k logs deploy/tcp-server -c server --since=2m | grep -q "HELLO id=$id " && return 0
    sleep 0.5
  done
  echo "connection $id never reached tcp-server"; cat "$TMP/$id.log"; return 1
}

# Server dies silently; the gateway's upstream keepalive must notice and close the client.
upstream() {
  local expect=$1 id="up-$RANDOM" rc=0
  log "upstream black-hole ($id), expect: $expect"
  start_client "$id"
  blackhole tcp-server
  wait "$CLIENT_PID" || rc=$?
  restore tcp-server
  cat "$TMP/$id.log"
  local after; after=$(sed -n 's/.*CLOSED .*after=\([0-9.]*\)s.*/\1/p' "$TMP/$id.log")
  if [[ $expect == detect ]]; then
    if [[ $rc -eq 0 && -n $after ]] && in_range "$after"; then pass "client closed after ${after}s"
    else fail "expected client close in ${LOW}-${HIGH}s (rc=$rc after=${after:-none})"; fi
  else
    if [[ $rc -eq 2 ]]; then pass "no keepalive: connection still open after ${MAX_WAIT}s"
    else fail "expected connection to stay open (rc=$rc after=${after:-none})"; fi
  fi
}

# Client dies silently; the gateway's downstream keepalive must notice and close the server side.
downstream() {
  local expect=$1 id="down-$RANDOM" dur=""
  log "downstream black-hole ($id), expect: $expect"
  start_client "$id"
  blackhole tcp-client
  for _ in $(seq "$MAX_WAIT"); do
    dur=$(k logs deploy/tcp-server -c server --since=5m | sed -n "s/.*CLOSE id=$id .*duration=\([0-9.]*\)s.*/\1/p")
    [[ -n $dur ]] && break
    sleep 1
  done
  wait "$CLIENT_PID" || true
  restore tcp-client
  k logs deploy/tcp-server -c server --since=5m | grep " id=$id " || true
  if [[ $expect == detect ]]; then
    if [[ -n $dur ]] && in_range "$dur"; then pass "gateway closed server side after ${dur}s"
    else fail "expected server-side close in ${LOW}-${HIGH}s (got ${dur:-none})"; fi
  else
    if [[ -z $dur ]]; then pass "no keepalive: server side still open after ${MAX_WAIT}s"
    else fail "expected server side to stay open (closed after ${dur}s)"; fi
  fi
}

log "waiting for app and gateway"
k rollout status deploy/tcp-server deploy/tcp-client deploy/$GW --timeout=120s

if [[ $SKIP_BASELINE != 1 ]]; then
  log "baseline: removing keepalive policies"
  k delete -f "$DIR/backendconfigpolicy.yaml" -f "$DIR/listenerpolicy.yaml" --ignore-not-found
  sleep "$SETTLE"
  upstream none
  downstream none
fi

log "applying BackendConfigPolicy (upstream keepalive)"
k apply -f "$DIR/backendconfigpolicy.yaml"
sleep "$SETTLE"
upstream detect

log "applying ListenerPolicy (downstream keepalive)"
k apply -f "$DIR/listenerpolicy.yaml"
sleep "$SETTLE"
downstream detect

log "result"
if [[ $FAILED -eq 0 ]]; then echo "ALL PASSED"; else echo "SOME CHECKS FAILED"; exit 1; fi
