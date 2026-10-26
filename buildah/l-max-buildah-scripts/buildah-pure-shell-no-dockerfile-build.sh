#!/usr/bin/env bash
# L-max: build an image with plain shell, no Dockerfile.
# Every layer is an explicit command (from, run, copy, config, commit), so loops,
# conditionals and generated content are ordinary shell. Useful for CI that
# builds images from templates, or where no Dockerfile frontend is available.
#
# Run: bash buildah-pure-shell-no-dockerfile-build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../../docker/l1-basic-dockerfile/python-app"
BASE=docker.io/library/python:3.14.9-slim-trixie
TAG=localhost/buildah-lmax-python:latest

CONTAINER=""
cleanup() { [ -z "$CONTAINER" ] || buildah rm "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "=== L-max: Buildah without a Dockerfile ==="

echo "--- Phase 1: base ---"
CONTAINER=$(buildah from "$BASE")

echo "--- Phase 2: environment ---"
buildah config \
  --env PYTHONDONTWRITEBYTECODE=1 \
  --env PYTHONUNBUFFERED=1 \
  --env PORT=5000 \
  "$CONTAINER"

echo "--- Phase 3: dependencies (before source, for cache reuse) ---"
buildah config --workingdir /app "$CONTAINER"
buildah copy "$CONTAINER" "$APP_DIR/requirements.txt" /app/requirements.txt
buildah run "$CONTAINER" -- pip install --no-cache-dir -r /app/requirements.txt

echo "--- Phase 4: application source ---"
buildah copy "$CONTAINER" "$APP_DIR/app.py" /app/app.py

echo "--- Phase 5: non-root user ---"
buildah run "$CONTAINER" -- useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app

echo "--- Phase 6: metadata (healthcheck needs --format docker below) ---"
buildah config \
  --user 10001:10001 \
  --port 5000 \
  --healthcheck "CMD python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)\"" \
  --healthcheck-interval 30s \
  --healthcheck-timeout 5s \
  --healthcheck-start-period 10s \
  --healthcheck-retries 3 \
  --cmd 'gunicorn --bind 0.0.0.0:5000 app:app' \
  --label org.opencontainers.image.title=buildah-lmax-python \
  --label org.opencontainers.image.description="Built entirely from shell, no Dockerfile" \
  "$CONTAINER"

echo "--- Phase 7: commit ---"
buildah commit --format docker "$CONTAINER" "$TAG"
buildah rm "$CONTAINER"
CONTAINER=""

echo "--- Result ---"
buildah images "$TAG"
podman image inspect "$TAG" \
  --format 'user={{.Config.User}} workdir={{.Config.WorkingDir}} ports={{.Config.ExposedPorts}} cmd={{.Config.Cmd}}'
buildah inspect --type image "$TAG" | jq -e '(.Docker.config.Healthcheck // .Docker.container_config.Healthcheck) != null' >/dev/null
echo "healthcheck present: yes"
echo "=== Done ==="
