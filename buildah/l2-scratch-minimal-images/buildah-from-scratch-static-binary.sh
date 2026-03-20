#!/usr/bin/env bash
# L2: Buildah — build minimal OCI image FROM scratch
# Demonstrates: compile static Go binary, put ONLY the binary in a scratch image
# Result: ~5MB image with zero OS, no shell, no libc, no attack surface
#
# Run: bash buildah-from-scratch-static-binary.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRATCH_TAG="go-scratch-buildah:latest"
BUILD_CONTAINER=""
SCRATCH_CONTAINER=""

cleanup() {
  [ -n "$BUILD_CONTAINER" ]   && buildah rm "$BUILD_CONTAINER"   2>/dev/null || true
  [ -n "$SCRATCH_CONTAINER" ] && buildah rm "$SCRATCH_CONTAINER" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== L2: Buildah FROM scratch — minimal static binary image ==="

# ── Step 1: Compile static binary in a Go builder container ──────────────────
echo ""
echo "--- Step 1: Compile static Go binary ---"
BUILD_CONTAINER=$(buildah from golang:1.22-alpine)

buildah run "$BUILD_CONTAINER" -- mkdir -p /build
buildah copy "$BUILD_CONTAINER" \
  "$REPO_ROOT/test-apps/go-app/go.mod" /build/go.mod
buildah copy "$BUILD_CONTAINER" \
  "$REPO_ROOT/test-apps/go-app/http-hello-world-server.go" /build/

buildah run "$BUILD_CONTAINER" -- sh -c \
  "cd /build && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags='-w -s' -o http-server http-hello-world-server.go"

echo "Binary compiled inside build container."

# ── Step 2: Create scratch image and copy only the binary ────────────────────
echo ""
echo "--- Step 2: Create FROM scratch image ---"
# 'scratch' = completely empty image; nothing exists except what we copy in
SCRATCH_CONTAINER=$(buildah from scratch)

# Copy CA certs so HTTPS works (extracted from builder)
buildah run "$BUILD_CONTAINER" -- cat /etc/ssl/certs/ca-certificates.crt > /tmp/ca-certificates.crt
buildah copy "$SCRATCH_CONTAINER" /tmp/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy the static binary — this is the ONLY thing in the image besides certs
buildah run "$BUILD_CONTAINER" -- cat /build/http-server > /tmp/http-server
chmod +x /tmp/http-server
buildah copy "$SCRATCH_CONTAINER" /tmp/http-server /http-server

# ── Step 3: Set image config ──────────────────────────────────────────────────
echo ""
echo "--- Step 3: Configure image metadata ---"
buildah config \
  --port 8080 \
  --entrypoint '["/http-server"]' \
  --label org.opencontainers.image.title="go-scratch-buildah" \
  --label org.opencontainers.image.description="Minimal Go binary in scratch image" \
  "$SCRATCH_CONTAINER"

# ── Step 4: Commit to image ───────────────────────────────────────────────────
echo ""
echo "--- Step 4: Commit scratch image ---"
buildah commit "$SCRATCH_CONTAINER" "$SCRATCH_TAG"

echo ""
echo "--- Image size comparison ---"
buildah images | grep -E "golang|go-scratch-buildah" || true

echo ""
echo "Scratch image '$SCRATCH_TAG' contains ONLY the static binary + CA certs."
echo "No shell, no OS packages, no libc — minimal attack surface."
echo ""
echo "=== Done ==="
