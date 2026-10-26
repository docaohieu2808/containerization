#!/usr/bin/env bash
# L4: a multi-unit Quadlet application: network + volume + pod + two containers.
# Installs the whole set, starts the pod unit, and asserts:
#   - Quadlet generated all five services without errors (-dryrun)
#   - both containers are healthy
#   - the web port is published on the host, the cache port is NOT
#   - the web container reaches the cache over the pod's shared localhost
#
# Run: bash quadlet-pod-install-and-check.sh   (KEEP=1 leaves it running)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=18084
UNITS=(app-net.network app-data.volume app.pod app-web.container app-cache.container)

QUADLET=""
for candidate in /usr/libexec/podman/quadlet /usr/lib/podman/quadlet; do
  if [ -x "$candidate" ]; then QUADLET=$candidate; break; fi
done
[ -n "$QUADLET" ] || { echo "quadlet binary not found" >&2; exit 1; }

cleanup() {
  if [ "${KEEP:-0}" != 1 ]; then
    systemctl --user stop app-pod.service >/dev/null 2>&1 || true
    for unit in "${UNITS[@]}"; do podman quadlet rm "$unit" >/dev/null 2>&1 || true; done
    systemctl --user daemon-reload || true
    podman volume rm -f app-data >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "=== L4: Quadlet pod, network and volume ==="

echo "--- 1. Dry run ---"
generated=$(QUADLET_UNIT_DIRS="$SCRIPT_DIR" "$QUADLET" -dryrun -user)
for service in app-net-network app-data-volume app-pod app-web app-cache; do
  grep -q "^---${service}.service---" <<<"$generated" || { echo "Quadlet did not generate ${service}.service" >&2; exit 1; }
done
echo "generated: app-net-network app-data-volume app-pod app-web app-cache"

echo "--- 2. Install and start ---"
for unit in "${UNITS[@]}"; do podman quadlet install "$SCRIPT_DIR/$unit"; done
systemctl --user daemon-reload
systemctl --user start app-pod.service
systemctl --user start app-web.service app-cache.service

echo "--- 3. Containers healthy ---"
for name in app-web app-cache; do
  for _ in $(seq 1 60); do
    status=$(podman inspect --format '{{.State.Health.Status}}' "$name" 2>/dev/null || true)
    [ "$status" = "healthy" ] && break
    sleep 2
  done
  echo "$name: ${status:-unknown}"
  if [ "${status:-}" != "healthy" ]; then
    podman ps -a >&2
    podman logs "$name" >&2 || true
    systemctl --user status "${name}.service" --no-pager >&2 || true
    exit 1
  fi
done

echo "--- 4. Port exposure ---"
curl -fsS "http://127.0.0.1:${PORT}/" | grep -q "Welcome to nginx"
echo "web published on 127.0.0.1:${PORT}: OK"
if ss -ltn | grep -q ':6379 '; then echo "cache port 6379 is exposed on the host" >&2; exit 1; fi
echo "cache port 6379 not exposed on the host: OK"

echo "--- 5. Shared localhost inside the pod ---"
reply=$(podman exec app-web sh -c "printf 'PING\r\n' | nc -w 2 127.0.0.1 6379")
echo "web -> cache: $reply"
grep -q PONG <<<"$reply"

echo "=== Done ==="
