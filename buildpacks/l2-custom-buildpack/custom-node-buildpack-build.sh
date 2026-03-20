#!/usr/bin/env bash
# L2: Custom buildpack — build script
# The build script runs when detect exits 0; it installs deps and configures the launch
#
# Buildpack contract:
#   $1 = layers directory  — where the buildpack writes its layers (cached between builds)
#   $2 = platform directory — contains env vars from pack build --env
#   $3 = build plan path   — TOML file with requires/provides from detect phase
#
# Layers:
#   Each layer is a directory under $LAYERS_DIR
#   Metadata TOML controls: cache=true (reuse layer), build=true (available at build), launch=true (in runtime image)

set -euo pipefail

LAYERS_DIR="$1"
PLATFORM_DIR="$2"
BUILD_PLAN_PATH="$3"

APP_DIR="$(pwd)"

echo "--- custom-node-buildpack: build phase ---"
echo "App dir:    $APP_DIR"
echo "Layers dir: $LAYERS_DIR"

# ── Layer: node_modules ───────────────────────────────────────────────────────
NODE_MODULES_LAYER="$LAYERS_DIR/node_modules"
mkdir -p "$NODE_MODULES_LAYER"

# Write layer metadata TOML
# cache=true: reuse this layer on next build if package.json unchanged
# launch=true: include this layer in the runtime image
cat > "$NODE_MODULES_LAYER.toml" <<TOML
[types]
cache = true
build = false
launch = true
TOML

# Install production dependencies into the layer
cd "$APP_DIR"
NODE_ENV=production npm install \
  --prefix "$NODE_MODULES_LAYER" \
  --omit=dev

# ── Layer: runtime config ─────────────────────────────────────────────────────
RUNTIME_LAYER="$LAYERS_DIR/runtime"
mkdir -p "$RUNTIME_LAYER"

cat > "$RUNTIME_LAYER.toml" <<TOML
[types]
cache = false
build = false
launch = true
TOML

# Write the launch process (what command runs the app)
# This replaces CMD/ENTRYPOINT in a Dockerfile
mkdir -p "$LAYERS_DIR/../launch"
cat > "$LAYERS_DIR/../launch.toml" <<TOML
[[processes]]
type = "web"
command = ["node", "express-hello-world-server.js"]
default = true
TOML

echo "--- custom-node-buildpack: build complete ---"
