#!/usr/bin/env bash
# MAX: Buildah — pure shell script build with NO Dockerfile
# Demonstrates:
#   - buildah unshare: enter user namespace for rootless operations
#   - buildah from: start from any base image
#   - buildah run: execute commands in container
#   - buildah copy: inject files
#   - buildah config: set metadata
#   - buildah commit: finalize image
#   - Full control over every layer — no Dockerfile DSL needed
#
# This approach is useful for:
#   - Programmatic image construction (loops, conditionals, dynamic content)
#   - CI pipelines that generate images from templates
#   - Building images without Docker or Dockerfile support
#
# Run: bash buildah-pure-shell-no-dockerfile-build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

IMAGE_TAG="myapp-pure-shell-buildah:latest"
WORKING_CONTAINER=""

cleanup() {
  if [ -n "$WORKING_CONTAINER" ]; then
    echo "Cleaning up working container: $WORKING_CONTAINER"
    buildah rm "$WORKING_CONTAINER" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "=== MAX: Buildah Pure Shell Build (No Dockerfile) ==="

# ── Phase 1: Start from base ──────────────────────────────────────────────────
echo ""
echo "--- Phase 1: Start from python:3.12-slim ---"
WORKING_CONTAINER=$(buildah from python:3.12-slim)
echo "Working container ID: $WORKING_CONTAINER"

# ── Phase 2: System setup ─────────────────────────────────────────────────────
echo ""
echo "--- Phase 2: System setup (timezone, CA certs, packages) ---"
buildah run "$WORKING_CONTAINER" -- apt-get update
buildah run "$WORKING_CONTAINER" -- apt-get install -y --no-install-recommends \
  ca-certificates \
  tzdata \
  curl
buildah run "$WORKING_CONTAINER" -- apt-get clean
buildah run "$WORKING_CONTAINER" -- rm -rf /var/lib/apt/lists/*

# Set timezone via environment (shell-driven — no RUN ln -sf needed)
buildah config --env TZ=UTC "$WORKING_CONTAINER"
buildah config --env PYTHONDONTWRITEBYTECODE=1 "$WORKING_CONTAINER"
buildah config --env PYTHONUNBUFFERED=1 "$WORKING_CONTAINER"

# ── Phase 3: Install Python dependencies ─────────────────────────────────────
echo ""
echo "--- Phase 3: Install Python dependencies ---"
buildah run "$WORKING_CONTAINER" -- mkdir -p /app
buildah copy "$WORKING_CONTAINER" \
  "$REPO_ROOT/test-apps/python-app/flask-app-pip-requirements.txt" \
  /app/requirements.txt
buildah run "$WORKING_CONTAINER" -- pip install --no-cache-dir -r /app/requirements.txt

# ── Phase 4: Copy application source ─────────────────────────────────────────
echo ""
echo "--- Phase 4: Copy application source ---"
buildah copy "$WORKING_CONTAINER" \
  "$REPO_ROOT/test-apps/python-app/flask-hello-world-server.py" \
  /app/flask-hello-world-server.py

# ── Phase 5: Security hardening (shell-driven) ───────────────────────────────
echo ""
echo "--- Phase 5: Security hardening ---"
buildah run "$WORKING_CONTAINER" -- useradd -r -u 1001 -s /bin/false appuser
buildah run "$WORKING_CONTAINER" -- chown -R appuser /app

# ── Phase 6: Set image metadata ───────────────────────────────────────────────
echo ""
echo "--- Phase 6: Set OCI metadata ---"
buildah config \
  --workingdir /app \
  --user appuser \
  --port 5000 \
  --env PORT=5000 \
  --healthcheck "CMD python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000/health')\"" \
  --healthcheck-interval 30s \
  --healthcheck-timeout 5s \
  --healthcheck-retries 3 \
  --cmd '["gunicorn", "--bind", "0.0.0.0:5000", "flask-hello-world-server:app"]' \
  --label org.opencontainers.image.title="myapp-pure-shell-buildah" \
  --label org.opencontainers.image.description="Built entirely from shell, no Dockerfile" \
  --label org.opencontainers.image.created="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$WORKING_CONTAINER"

# ── Phase 7: Commit final image ───────────────────────────────────────────────
echo ""
echo "--- Phase 7: Commit image ---"
buildah commit "$WORKING_CONTAINER" "$IMAGE_TAG"
echo "Image committed: $IMAGE_TAG"

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
echo "--- Result ---"
buildah images "$IMAGE_TAG"
buildah inspect "$IMAGE_TAG" | python3 -c "
import json, sys
data = json.load(sys.stdin)
cfg = data.get('OCIv1', {}).get('config', {})
print('User:    ', cfg.get('User'))
print('WorkDir: ', cfg.get('WorkingDir'))
print('Ports:   ', list(cfg.get('ExposedPorts', {}).keys()))
print('Cmd:     ', cfg.get('Cmd'))
"

echo ""
echo "=== Done. Image '$IMAGE_TAG' built entirely via shell — no Dockerfile needed ==="
