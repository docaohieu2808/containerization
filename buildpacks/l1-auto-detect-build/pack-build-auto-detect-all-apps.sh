#!/usr/bin/env bash
# L1: Buildpacks — pack build with Paketo buildpacks (auto-detect language)
# Demonstrates:
#   - pack build: detect language automatically, build OCI image, no Dockerfile needed
#   - Paketo builder: includes buildpacks for Node, Python, Go, Java, Ruby, etc.
#   - pack inspect: show what buildpacks were applied
#   - pack sbom: software bill of materials
#
# Prerequisites: pack CLI installed (https://buildpacks.io/docs/tools/pack/)
#   Ubuntu: curl -sSL https://github.com/buildpacks/pack/releases/download/v0.36.4/pack-v0.36.4-linux.tgz | tar xz && sudo mv pack /usr/local/bin/
#
# Run: bash pack-build-auto-detect-all-apps.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Paketo full builder — supports most languages
BUILDER="paketobuildpacks/builder-jammy-base"

echo "=== L1: pack build — Auto-detect language, no Dockerfile ==="
echo "Builder: $BUILDER"

# ── Build Node.js app ─────────────────────────────────────────────────────────
echo ""
echo "--- Building Node.js app ---"
# pack detects package.json → applies Node.js buildpack automatically
pack build node-paketo:latest \
  --path "$REPO_ROOT/test-apps/node-app" \
  --builder "$BUILDER" \
  --env "NODE_ENV=production"

echo "Node image built: node-paketo:latest"

# ── Build Python app ──────────────────────────────────────────────────────────
echo ""
echo "--- Building Python app ---"
# pack detects flask-app-pip-requirements.txt → applies Python buildpack
# Note: Paketo Python buildpack looks for requirements.txt by default
# We pass the custom filename via env var
pack build python-paketo:latest \
  --path "$REPO_ROOT/test-apps/python-app" \
  --builder "$BUILDER" \
  --env "BP_PIP_REQUIREMENTS=flask-app-pip-requirements.txt"

echo "Python image built: python-paketo:latest"

# ── Build Go app ──────────────────────────────────────────────────────────────
echo ""
echo "--- Building Go app ---"
# pack detects go.mod → applies Go buildpack automatically
pack build go-paketo:latest \
  --path "$REPO_ROOT/test-apps/go-app" \
  --builder "$BUILDER"

echo "Go image built: go-paketo:latest"

# ── Inspect what buildpacks were applied ─────────────────────────────────────
echo ""
echo "--- Inspecting node-paketo:latest (which buildpacks ran?) ---"
pack inspect node-paketo:latest

echo ""
echo "--- All built images ---"
docker images | grep -E "node-paketo|python-paketo|go-paketo" || true

echo ""
echo "=== Done. Images built with zero Dockerfile — Paketo auto-detected language ==="
