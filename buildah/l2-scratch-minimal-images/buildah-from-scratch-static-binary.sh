#!/usr/bin/env bash
# L2: Buildah builds a minimal image FROM scratch.
# Compiles the Go service in a toolchain container, then copies ONLY the static
# binary into an empty image: no shell, no libc, no package manager.
#
# Run: bash buildah-from-scratch-static-binary.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../../docker/l2-multi-stage-builds/go-scratch"
GO_IMAGE=docker.io/library/golang:1.27.3-alpine3.24
TAG=localhost/buildah-l2-go-scratch:latest

BUILD_CONTAINER=""
SCRATCH_CONTAINER=""
cleanup() {
  for c in "$BUILD_CONTAINER" "$SCRATCH_CONTAINER"; do
    [ -z "$c" ] || buildah rm "$c" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

echo "=== L2: Buildah FROM scratch ==="

echo "--- 1. Compile a static binary in a Go container ---"
BUILD_CONTAINER=$(buildah from "$GO_IMAGE")
buildah config --workingdir /src "$BUILD_CONTAINER"
buildah copy "$BUILD_CONTAINER" "$APP_DIR/go.mod" "$APP_DIR/main.go" /src/
# No GOARCH: the container's own architecture is the target, so this works on
# amd64 and arm64 hosts alike (l3 shows explicit cross-compilation).
buildah run "$BUILD_CONTAINER" -- sh -c \
  'CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server .'

echo "--- 2. Empty image + the binary ---"
SCRATCH_CONTAINER=$(buildah from scratch)
buildah copy --from "$BUILD_CONTAINER" "$SCRATCH_CONTAINER" /out/server /server

echo "--- 3. Configure ---"
# Exec-form healthcheck: scratch has no shell, so the binary probes itself.
buildah config \
  --user 65532:65532 \
  --port 8080 \
  --entrypoint '["/server"]' \
  --healthcheck "CMD /server -healthcheck" \
  --healthcheck-interval 30s \
  --healthcheck-timeout 3s \
  --healthcheck-start-period 5s \
  --healthcheck-retries 3 \
  --label org.opencontainers.image.title=buildah-l2-go-scratch \
  "$SCRATCH_CONTAINER"

echo "--- 4. Commit (docker format keeps the HEALTHCHECK) ---"
buildah commit --format docker "$SCRATCH_CONTAINER" "$TAG"
buildah images "$TAG"

size=$(podman image inspect "$TAG" --format '{{.Size}}')
echo "image size: ${size} bytes (contains one file: /server)"
echo "=== Done ==="
