#!/usr/bin/env bash
# L-max: create a custom builder, inspect it, and build three apps with it.
#
# Run: bash pack-create-and-use-custom-builder.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS="$SCRIPT_DIR/../../docker/l1-basic-dockerfile"
BUILDER_IMAGE=myorg/custom-builder:latest

echo "=== L-max: custom Buildpacks builder ==="

echo "--- 1. Create the builder image ---"
pack builder create "$BUILDER_IMAGE" --config "$SCRIPT_DIR/custom-builder-descriptor.toml"

echo "--- 2. Inspect it (buildpacks, detection order, lifecycle, run image) ---"
pack builder inspect "$BUILDER_IMAGE"

echo "--- 3. Build three apps with the one builder ---"
pack build node-via-custom-builder:latest   --path "$APPS/node-app"   --builder "$BUILDER_IMAGE" --trust-builder --pull-policy if-not-present
pack build python-via-custom-builder:latest --path "$APPS/python-app" --builder "$BUILDER_IMAGE" --trust-builder --pull-policy if-not-present
pack build go-via-custom-builder:latest     --path "$APPS/go-app"     --builder "$BUILDER_IMAGE" --trust-builder --pull-policy if-not-present

echo "=== Done ==="
echo "Publish the builder with: docker push $BUILDER_IMAGE"
