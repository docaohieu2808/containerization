#!/usr/bin/env bash
# L1: Cloud Native Buildpacks. `pack build` inspects the source, picks the
# matching buildpacks (Node, Python, Go...), and produces an OCI image with no
# Dockerfile. The builder is pinned to an exact version for reproducible builds.
#
# Prerequisites: Docker (or a Docker-compatible daemon) and the pack CLI
#   https://buildpacks.io/docs/tools/pack/   (this repo is tested with pack v0.40.10)
#
# Run: bash pack-build-auto-detect-all-apps.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS="$SCRIPT_DIR/../../docker/l1-basic-dockerfile"

# Paketo builder on Ubuntu 24.04 (noble), with the Node, Python and Go buildpacks inside.
# Releases: https://github.com/paketo-buildpacks/ubuntu-noble-builder/releases
BUILDER=docker.io/paketobuildpacks/ubuntu-noble-builder:0.0.207

echo "=== L1: pack build, language auto-detected ==="
echo "builder: $BUILDER"

echo
echo "--- Node.js (detected from package.json + package-lock.json) ---"
pack build node-paketo:latest --path "$APPS/node-app" --builder "$BUILDER" --trust-builder

echo
echo "--- Python (detected from requirements.txt; start command from the Procfile) ---"
pack build python-paketo:latest --path "$APPS/python-app" --builder "$BUILDER" --trust-builder

echo
echo "--- Go (detected from go.mod) ---"
pack build go-paketo:latest --path "$APPS/go-app" --builder "$BUILDER" --trust-builder

echo
echo "--- Which buildpacks produced node-paketo? ---"
pack inspect node-paketo:latest

echo
echo "--- Software bill of materials ---"
sbom_dir=$(mktemp -d)
pack sbom download node-paketo:latest --output-dir "$sbom_dir"
find "$sbom_dir" -type f | head -5

echo "=== Done. Images built with no Dockerfile ==="
