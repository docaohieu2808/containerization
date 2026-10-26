#!/usr/bin/env bash
# L2: Podman pods. Containers in a pod share one network namespace (one IP,
# one localhost) like the containers of a Kubernetes Pod.
# Demonstrates (and asserts):
#   - `podman pod create --publish`: the pod, not the container, owns the host port
#   - a sidecar reaching the web container over the pod's shared localhost
#   - inspecting and removing the pod
#
# Run: bash podman-pod-create-and-run-example.sh   (CLEANUP=false keeps the pod)
set -euo pipefail

POD=demo-pod
PORT=${POD_PORT:-18082}
CLEANUP=${CLEANUP:-true}
NGINX=docker.io/library/nginx:1.30.6-alpine3.24-slim
ALPINE=docker.io/library/alpine:3.24.3

cleanup() {
  if [ "$CLEANUP" = "true" ]; then
    podman pod rm -f "$POD" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
podman pod rm -f "$POD" >/dev/null 2>&1 || true

echo "=== L2: Podman pod ==="

echo "--- 1. Create the pod (owns the published port) ---"
podman pod create --name "$POD" --publish "${PORT}:80"

echo "--- 2. nginx in the pod ---"
podman run -d --pod "$POD" --name "${POD}-nginx" "$NGINX"

echo "--- 3. Sidecar in the same pod: reaches nginx on localhost ---"
podman run -d --pod "$POD" --name "${POD}-sidecar" "$ALPINE" \
  sh -c 'while true; do wget -q -O /dev/null http://127.0.0.1:80/ && echo "sidecar: nginx reachable on localhost"; sleep 2; done'

echo "--- 4. Inspect ---"
podman pod ps
podman ps --pod --filter "pod=${POD}"

echo "--- 5. Verify ---"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/" 2>/dev/null | grep -q "Welcome to nginx"; then
    reached=1
    break
  fi
  sleep 1
done
[ "${reached:-0}" = 1 ] || { echo "nginx not reachable through the pod port" >&2; exit 1; }
echo "host -> pod port ${PORT} -> nginx: OK"

for _ in $(seq 1 15); do
  if podman logs "${POD}-sidecar" 2>&1 | grep -q "nginx reachable on localhost"; then
    seen=1
    break
  fi
  sleep 1
done
[ "${seen:-0}" = 1 ] || { echo "sidecar could not reach nginx over the shared localhost" >&2; exit 1; }
echo "sidecar -> localhost:80 (shared network namespace): OK"

echo "=== Done ==="
