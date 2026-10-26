#!/usr/bin/env bash
# L-max: run a Kubernetes manifest with `podman kube play`, verify it, tear it down.
# Run: bash podman-kube-play-run-and-teardown.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/nginx-pod-kubernetes-manifest.yaml"
PORT=18085

cleanup() { podman kube down "$MANIFEST" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "=== L-max: podman kube play ==="

echo "--- 1. Play the manifest ---"
podman kube play "$MANIFEST"

echo "--- 2. Pods and containers ---"
podman pod ps
podman ps --pod

echo "--- 3. Verify the ConfigMap-backed page is served ---"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/" 2>/dev/null | grep -q "Hello from podman kube play"; then
    reached=1
    break
  fi
  sleep 1
done
[ "${reached:-0}" = 1 ] || { echo "nginx not reachable on port ${PORT}" >&2; podman pod ps; exit 1; }
echo "GET http://127.0.0.1:${PORT}/ -> ConfigMap content"

for _ in $(seq 1 20); do
  if podman logs nginx-demo-pod-log-watcher 2>&1 | grep -q "nginx ok"; then
    seen=1
    break
  fi
  sleep 1
done
[ "${seen:-0}" = 1 ] || { echo "sidecar never reached nginx over the pod's localhost" >&2; exit 1; }
echo "sidecar -> localhost:80 over the shared network namespace: OK"

echo "--- 4. Teardown ---"
podman kube down "$MANIFEST"
if podman pod exists nginx-demo-pod; then echo "pod still exists after kube down" >&2; exit 1; fi
echo "Torn down."
