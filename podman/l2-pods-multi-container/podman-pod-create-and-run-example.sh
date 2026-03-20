#!/usr/bin/env bash
# L2: Podman Pods — multiple containers sharing network and PID namespace
# Demonstrates:
#   - podman pod create: create a pod (shared network namespace)
#   - Add containers to pod — they share localhost
#   - podman pod start/stop/rm
#   - Inspect pod and containers
#
# Pods map to Kubernetes Pod concept: containers in a pod share:
#   - Network namespace (same IP, same ports — no port conflicts allowed)
#   - Optional: PID namespace (--share pid)
#   - Optional: IPC namespace
#
# Run: bash podman-pod-create-and-run-example.sh

set -euo pipefail

POD_NAME="demo-pod"
CLEANUP=${CLEANUP:-true}

echo "=== L2: Podman Pod Demo ==="

# ── 1. Create the pod ────────────────────────────────────────────────────────
echo ""
echo "--- 1. Creating pod '$POD_NAME' ---"
# --share net,uts: share network + hostname namespace (default)
# --publish 8080:80: map host 8080 → pod's port 80 (configured on pod, not container)
podman pod create \
  --name "$POD_NAME" \
  --share net,uts \
  --publish 8080:80

# ── 2. Add nginx container to pod ────────────────────────────────────────────
echo ""
echo "--- 2. Adding nginx container to pod ---"
# Pod containers don't need -p; the pod owns the port mapping
podman run -d \
  --pod "$POD_NAME" \
  --name "${POD_NAME}-nginx" \
  nginx:alpine

# ── 3. Add sidecar container (shares localhost with nginx) ───────────────────
echo ""
echo "--- 3. Adding sidecar (log tailer) container to pod ---"
# This container can reach nginx on localhost:80 (shared network namespace)
podman run -d \
  --pod "$POD_NAME" \
  --name "${POD_NAME}-sidecar" \
  alpine:3.19 \
  sh -c "while true; do wget -qO- http://localhost:80 2>&1 | head -1; sleep 5; done"

# ── 4. Inspect the pod ──────────────────────────────────────────────────────
echo ""
echo "--- 4. Pod status ---"
podman pod ps
echo ""
podman ps --pod --filter pod="$POD_NAME"

# ── 5. Show shared network namespace ────────────────────────────────────────
echo ""
echo "--- 5. Both containers share the same network namespace (same IP) ---"
podman exec "${POD_NAME}-nginx"   ip addr show eth0 2>/dev/null || true
podman exec "${POD_NAME}-sidecar" ip addr show eth0 2>/dev/null || true

# ── 6. Cleanup ───────────────────────────────────────────────────────────────
if [ "$CLEANUP" = "true" ]; then
  echo ""
  echo "--- 6. Cleanup: stopping and removing pod ---"
  podman pod stop "$POD_NAME"
  podman pod rm   "$POD_NAME"
  echo "Pod removed."
fi

echo ""
echo "=== Done ==="
