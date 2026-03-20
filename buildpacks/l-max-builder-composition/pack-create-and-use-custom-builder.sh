#!/usr/bin/env bash
# MAX: Create a custom Buildpacks builder and use it to build apps
# Demonstrates:
#   - pack builder create: package buildpacks + stack into a single builder image
#   - pack build --builder: use the custom builder for any app
#   - pack builder suggest: show official builders
#
# Run: bash pack-create-and-use-custom-builder.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

BUILDER_IMAGE="myorg/custom-builder:latest"
BUILDER_CONFIG="$SCRIPT_DIR/custom-builder-descriptor.toml"

echo "=== MAX: Custom Buildpacks Builder ==="

# ── Step 1: Show available official builders ──────────────────────────────────
echo ""
echo "--- Step 1: Official builders (for reference) ---"
pack builder suggest

# ── Step 2: Create custom builder image ──────────────────────────────────────
echo ""
echo "--- Step 2: Creating custom builder: $BUILDER_IMAGE ---"
echo "Config: $BUILDER_CONFIG"
pack builder create "$BUILDER_IMAGE" \
  --config "$BUILDER_CONFIG" \
  --pull-policy if-not-present

echo "Custom builder created: $BUILDER_IMAGE"

# ── Step 3: Inspect the builder ───────────────────────────────────────────────
echo ""
echo "--- Step 3: Inspect builder (shows included buildpacks + detection order) ---"
pack builder inspect "$BUILDER_IMAGE"

# ── Step 4: Use custom builder to build Node app ─────────────────────────────
echo ""
echo "--- Step 4: Build Node app using custom builder ---"
pack build node-via-custom-builder:latest \
  --path "$REPO_ROOT/test-apps/node-app" \
  --builder "$BUILDER_IMAGE" \
  --trust-builder

echo "Node app built: node-via-custom-builder:latest"

# ── Step 5: Use custom builder to build Python app ───────────────────────────
echo ""
echo "--- Step 5: Build Python app using custom builder ---"
pack build python-via-custom-builder:latest \
  --path "$REPO_ROOT/test-apps/python-app" \
  --builder "$BUILDER_IMAGE" \
  --trust-builder

echo "Python app built: python-via-custom-builder:latest"

# ── Step 6: Use custom builder to build Go app ───────────────────────────────
echo ""
echo "--- Step 6: Build Go app using custom builder ---"
pack build go-via-custom-builder:latest \
  --path "$REPO_ROOT/test-apps/go-app" \
  --builder "$BUILDER_IMAGE" \
  --trust-builder

echo "Go app built: go-via-custom-builder:latest"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "--- Built images via custom builder ---"
docker images | grep -E "node-via-custom|python-via-custom|go-via-custom" || true

echo ""
echo "=== Done. All apps built using single custom builder: $BUILDER_IMAGE ==="
echo "Publish builder: docker push $BUILDER_IMAGE"
echo "Team usage:      pack build <app> --builder $BUILDER_IMAGE"
