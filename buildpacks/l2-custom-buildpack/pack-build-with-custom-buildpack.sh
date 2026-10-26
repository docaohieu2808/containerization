#!/usr/bin/env bash
# L2: build with a buildpack you wrote. `--buildpack` replaces the builder's own
# detection with an explicit group, run in order:
#   1. paketo-buildpacks/node-engine  provides the `node` dependency (node + npm)
#   2. ./custom-node                   requires `node`, installs deps, sets the start command
#
# Run: bash pack-build-with-custom-buildpack.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$SCRIPT_DIR/../../docker/l1-basic-dockerfile/node-app"

BUILDER=docker.io/paketobuildpacks/ubuntu-noble-builder:0.0.207
# https://github.com/paketo-buildpacks/node-engine/releases
NODE_ENGINE=docker://docker.io/paketobuildpacks/node-engine:8.11.0

echo "=== L2: pack build with a custom buildpack ==="
pack build node-custom-buildpack:latest \
  --path "$APP" \
  --builder "$BUILDER" \
  --trust-builder \
  --buildpack "$NODE_ENGINE" \
  --buildpack "$SCRIPT_DIR/custom-node" \
  --env 'BP_NODE_VERSION=24.*'

echo
pack inspect node-custom-buildpack:latest
echo "=== Done ==="
