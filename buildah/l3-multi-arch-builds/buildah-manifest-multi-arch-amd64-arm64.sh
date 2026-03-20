#!/usr/bin/env bash
# L3: Buildah multi-arch manifest — build linux/amd64 + linux/arm64 images
# and combine them into a single multi-arch manifest list (OCI image index)
#
# A manifest list lets `docker pull myimage` automatically get the right arch
#
# Prerequisites: qemu-user-static installed for cross-arch emulation
#   Ubuntu: sudo apt-get install qemu-user-static
#   Or use --arch flag with native builders
#
# Run: bash buildah-manifest-multi-arch-amd64-arm64.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

MANIFEST_NAME="myapp-multiarch:latest"
AMD64_TAG="myapp-multiarch:amd64"
ARM64_TAG="myapp-multiarch:arm64"

echo "=== L3: Buildah Multi-arch Manifest ==="

# ── Step 1: Build amd64 image ────────────────────────────────────────────────
echo ""
echo "--- Step 1: Build linux/amd64 image ---"
buildah bud \
  --arch amd64 \
  --os linux \
  --tag "$AMD64_TAG" \
  --file "$REPO_ROOT/docker/l2-multi-stage-builds/go-app-multistage-scratch.Dockerfile" \
  "$REPO_ROOT"

echo "amd64 image: $AMD64_TAG"

# ── Step 2: Build arm64 image ────────────────────────────────────────────────
echo ""
echo "--- Step 2: Build linux/arm64 image (via QEMU emulation or native) ---"
# --arch arm64 tells Buildah to target arm64
# If qemu-user-static is installed, Go cross-compilation handles the rest
buildah bud \
  --arch arm64 \
  --os linux \
  --tag "$ARM64_TAG" \
  --file "$REPO_ROOT/docker/l2-multi-stage-builds/go-app-multistage-scratch.Dockerfile" \
  "$REPO_ROOT"

echo "arm64 image: $ARM64_TAG"

# ── Step 3: Create manifest list ─────────────────────────────────────────────
echo ""
echo "--- Step 3: Create multi-arch manifest list ---"
# Remove existing manifest if present
buildah manifest rm "$MANIFEST_NAME" 2>/dev/null || true
buildah manifest create "$MANIFEST_NAME"

# Add each arch image to the manifest
buildah manifest add "$MANIFEST_NAME" "$AMD64_TAG"
buildah manifest add "$MANIFEST_NAME" "$ARM64_TAG"

echo "Manifest created: $MANIFEST_NAME"

# ── Step 4: Inspect manifest ──────────────────────────────────────────────────
echo ""
echo "--- Step 4: Inspect manifest ---"
buildah manifest inspect "$MANIFEST_NAME"

# ── Step 5: Push manifest to registry ────────────────────────────────────────
echo ""
echo "--- Step 5: Push multi-arch manifest (example command) ---"
echo "# Push all arch images + manifest list in one command:"
echo "buildah manifest push --all $MANIFEST_NAME docker://registry.example.com/$MANIFEST_NAME"
echo ""
echo "# Docker Hub example:"
echo "buildah manifest push --all $MANIFEST_NAME docker://docker.io/myorg/myapp:latest"

echo ""
echo "=== Done. '$MANIFEST_NAME' is a manifest list covering amd64 + arm64 ==="
