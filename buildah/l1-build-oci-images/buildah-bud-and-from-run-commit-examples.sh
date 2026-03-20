#!/usr/bin/env bash
# L1: Buildah — build OCI images two ways:
#   A) buildah bud   — build from a Dockerfile (like docker build)
#   B) buildah from/run/copy/commit — imperative API (no Dockerfile needed)
#
# Buildah advantages over docker build:
#   - No daemon required
#   - Rootless by default
#   - Fine-grained layer control
#   - Can push to any OCI registry
#
# Run: bash buildah-bud-and-from-run-commit-examples.sh

set -euo pipefail

IMAGE_TAG="myapp-buildah:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== L1: Buildah OCI Image Build ==="

# ══════════════════════════════════════════════════════════════════════════════
# Method A: buildah bud (Build Using Dockerfile)
# Equivalent to: docker build -f <dockerfile>
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "--- Method A: buildah bud (Dockerfile-based build) ---"

buildah bud \
  --tag "$IMAGE_TAG" \
  --file "$REPO_ROOT/docker/l1-basic-dockerfile/node-app-basic.Dockerfile" \
  "$REPO_ROOT"

echo "Image built: $IMAGE_TAG"
buildah images "$IMAGE_TAG"

# ══════════════════════════════════════════════════════════════════════════════
# Method B: Imperative buildah from/run/copy/commit
# No Dockerfile — each step is a shell command
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "--- Method B: Imperative buildah from/run/copy/commit ---"

IMPERATIVE_TAG="myapp-imperative:latest"

# Start with a base image — creates a working container
CONTAINER=$(buildah from node:20-alpine)
echo "Working container: $CONTAINER"

# Run commands in the container (equivalent to RUN in Dockerfile)
buildah run "$CONTAINER" -- apk add --no-cache wget

# Set working directory
buildah config --workingdir /app "$CONTAINER"

# Copy files into container (equivalent to COPY in Dockerfile)
buildah copy "$CONTAINER" \
  "$REPO_ROOT/test-apps/node-app/package.json" \
  /app/package.json

buildah run "$CONTAINER" -- npm install --omit=dev

buildah copy "$CONTAINER" \
  "$REPO_ROOT/test-apps/node-app/express-hello-world-server.js" \
  /app/express-hello-world-server.js

# Add user (equivalent to RUN adduser in Dockerfile)
buildah run "$CONTAINER" -- addgroup -S appgroup
buildah run "$CONTAINER" -- adduser -S appuser -G appgroup

# Set OCI config metadata
buildah config \
  --user appuser \
  --port 3000 \
  --env NODE_ENV=production \
  --healthcheck "CMD wget -qO- http://localhost:3000/health || exit 1" \
  --healthcheck-interval 30s \
  --cmd '["node", "express-hello-world-server.js"]' \
  --label org.opencontainers.image.title="myapp-imperative" \
  "$CONTAINER"

# Commit the container to an image
buildah commit "$CONTAINER" "$IMPERATIVE_TAG"
echo "Imperative image committed: $IMPERATIVE_TAG"

# Cleanup working container
buildah rm "$CONTAINER"

# ── Show results ──────────────────────────────────────────────────────────────
echo ""
echo "--- Built images ---"
buildah images | grep -E "myapp-buildah|myapp-imperative" || true

# ── Optional: push to registry ───────────────────────────────────────────────
echo ""
echo "To push: buildah push $IMAGE_TAG docker://registry.example.com/$IMAGE_TAG"
echo "To push to docker daemon: buildah push $IMAGE_TAG docker-daemon:$IMAGE_TAG"

echo ""
echo "=== Done ==="
