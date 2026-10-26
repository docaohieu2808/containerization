#!/usr/bin/env bash
# L1: Buildah builds container images two ways, rootless and daemonless:
#   A) buildah build  - from a Dockerfile (`buildah bud` is the old alias)
#   B) buildah from / run / copy / config / commit - the imperative API
#
# Both use --format docker. Buildah's default OCI image format has no HEALTHCHECK
# field, so a healthcheck set with `buildah config --healthcheck` is silently
# dropped on commit unless the image is committed in docker format.
#
# Run: bash buildah-build-and-from-run-commit-examples.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../../docker/l1-basic-dockerfile/node-app"
NODE_IMAGE=docker.io/library/node:24.22.1-alpine3.24

TAG_A=localhost/buildah-l1-dockerfile:latest
TAG_B=localhost/buildah-l1-imperative:latest

CONTAINER=""
cleanup() { [ -z "$CONTAINER" ] || buildah rm "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

has_healthcheck() {
  buildah inspect --type image "$1" | jq '.Docker | {config: .config.Healthcheck, container_config: .container_config.Healthcheck}'
  buildah inspect --type image "$1" | jq -e '(.Docker.config.Healthcheck // .Docker.container_config.Healthcheck) != null' >/dev/null
}

echo "=== L1: Buildah ==="
buildah --version

echo
echo "--- A) buildah build (Dockerfile) ---"
# The build context is the example's own directory; nothing outside it is read.
buildah build --format docker --tag "$TAG_A" --file "$APP_DIR/Dockerfile" "$APP_DIR"
buildah images "$TAG_A"
has_healthcheck "$TAG_A"
echo "healthcheck kept in image A: yes"

echo
echo "--- B) from / run / copy / config / commit (no Dockerfile) ---"
CONTAINER=$(buildah from "$NODE_IMAGE")
buildah config --workingdir /app "$CONTAINER"

# Same order as the Dockerfile: manifests, install, then source.
buildah copy "$CONTAINER" "$APP_DIR/package.json" "$APP_DIR/package-lock.json" /app/
buildah run "$CONTAINER" -- npm ci --omit=dev
buildah copy "$CONTAINER" "$APP_DIR/server.js" /app/server.js

buildah config \
  --user node \
  --port 3000 \
  --env NODE_ENV=production \
  --healthcheck "CMD node -e \"fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))\"" \
  --healthcheck-interval 30s \
  --healthcheck-timeout 5s \
  --healthcheck-start-period 10s \
  --healthcheck-retries 3 \
  --cmd 'node server.js' \
  --label org.opencontainers.image.title=buildah-l1-imperative \
  "$CONTAINER"

buildah commit --format docker "$CONTAINER" "$TAG_B"
buildah rm "$CONTAINER"
CONTAINER=""
has_healthcheck "$TAG_B"
echo "healthcheck kept in image B: yes"

echo
echo "--- Built images ---"
buildah images

echo
echo "Push examples:"
echo "  buildah push $TAG_A docker://registry.example.com/team/app:latest"
echo "  buildah push $TAG_A docker-daemon:app:latest"
echo "=== Done ==="
