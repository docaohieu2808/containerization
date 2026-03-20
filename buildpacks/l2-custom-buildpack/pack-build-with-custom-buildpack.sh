#!/usr/bin/env bash
# L2: Use a custom buildpack with pack build
# Demonstrates: --buildpack flag to inject local buildpack into the build
#
# Run: bash pack-build-with-custom-buildpack.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILDPACK_DIR="$SCRIPT_DIR"

echo "=== L2: pack build with custom buildpack ==="

# Ensure detect/build scripts are executable
chmod +x "$BUILDPACK_DIR/custom-node-buildpack-detect.sh"
chmod +x "$BUILDPACK_DIR/custom-node-buildpack-build.sh"

# Rename scripts to match buildpack contract (bin/detect, bin/build)
# Pack expects them at: <buildpack-root>/bin/detect and <buildpack-root>/bin/build
mkdir -p "$BUILDPACK_DIR/bin"
cp "$BUILDPACK_DIR/custom-node-buildpack-detect.sh" "$BUILDPACK_DIR/bin/detect"
cp "$BUILDPACK_DIR/custom-node-buildpack-build.sh"  "$BUILDPACK_DIR/bin/build"
chmod +x "$BUILDPACK_DIR/bin/detect" "$BUILDPACK_DIR/bin/build"
cp "$BUILDPACK_DIR/custom-node-buildpack-descriptor.toml" "$BUILDPACK_DIR/buildpack.toml"

# Build using our custom buildpack
# --buildpack: path to local buildpack directory
# --builder:   still need a builder for the run image (stack)
pack build node-custom-buildpack:latest \
  --path "$REPO_ROOT/test-apps/node-app" \
  --buildpack "$BUILDPACK_DIR" \
  --builder "paketobuildpacks/builder-jammy-base" \
  --trust-builder

echo ""
echo "Image built: node-custom-buildpack:latest"
pack inspect node-custom-buildpack:latest

echo ""
echo "=== Done ==="
