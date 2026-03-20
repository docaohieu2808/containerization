#!/usr/bin/env bash
# L2: Custom buildpack — detect script
# The detect script decides IF this buildpack applies to the app source
# Exit 0 = this buildpack handles the app; Exit 1 = skip this buildpack
#
# Buildpack contract:
#   bin/detect <platform-dir> → stdout: buildpack name/version, exit 0 or 1
#   bin/build  <layers-dir> <platform-dir> <plan-path> → build the layer
#
# This detect script: applies when package.json exists (Node.js app)

set -euo pipefail

# $1 = platform directory (contains env vars, etc.)
PLATFORM_DIR="${1:-/platform}"
BUILD_PLAN_PATH="${2:-/dev/null}"

APP_DIR="$(pwd)"  # pack sets CWD to app source directory

# Detect: does this look like a Node.js app?
if [ -f "$APP_DIR/package.json" ]; then
  echo "custom-node-buildpack"  # buildpack name written to stdout
  exit 0                         # 0 = I can build this app
else
  exit 1                         # 1 = not my app, skip me
fi
