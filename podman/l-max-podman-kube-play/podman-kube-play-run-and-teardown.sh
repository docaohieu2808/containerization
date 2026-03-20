#!/usr/bin/env bash
# MAX: podman kube play — run and teardown K8s YAML with Podman
# Run: bash podman-kube-play-run-and-teardown.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/nginx-pod-kubernetes-manifest.yaml"

echo "=== MAX: podman kube play ==="

# ── 1. Play the manifest ──────────────────────────────────────────────────────
echo ""
echo "--- 1. Starting pod from K8s YAML ---"
podman kube play "$MANIFEST"

# ── 2. Check running pods and containers ─────────────────────────────────────
echo ""
echo "--- 2. Running pods ---"
podman pod ps

echo ""
echo "--- Containers in pod ---"
podman ps --pod

# ── 3. Test connectivity ──────────────────────────────────────────────────────
echo ""
echo "--- 3. Testing nginx on http://localhost:8080 ---"
sleep 2
curl -sf http://localhost:8080 || echo "Not reachable yet — give it a moment"

# ── 4. Teardown ───────────────────────────────────────────────────────────────
echo ""
echo "--- 4. Tearing down (podman kube down) ---"
podman kube down "$MANIFEST"
echo "Torn down."

echo ""
echo "=== Done. Use 'podman kube play <manifest>' to run any K8s Pod/Deployment YAML locally ==="
