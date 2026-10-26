#!/usr/bin/env bash
# L3: Buildah multi-arch: build linux/amd64 and linux/arm64 images, then group
# them in a manifest list (OCI image index) so `pull` picks the right one per machine.
#
# The Dockerfile cross-compiles with TARGETOS/TARGETARCH on the build host's own
# architecture, so no QEMU is needed to produce the arm64 image. QEMU
# (qemu-user-static) is only needed to RUN the arm64 image or to RUN steps in it.
#
# Run: bash buildah-manifest-multi-arch-amd64-arm64.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../../docker/l3-buildkit-advanced/go-multiarch"
MANIFEST=localhost/buildah-l3-multiarch:latest

echo "=== L3: Buildah multi-arch manifest ==="

# ELF header byte 18 is e_machine: 0x3e = x86-64, 0xb7 = AArch64.
check_binary_arch() {
  local arch=$1 want=$2 c machine
  c=$(buildah from --arch "$arch" --pull=never "localhost/buildah-l3-multiarch:$arch")
  machine=$(buildah unshare sh -c "mnt=\$(buildah mount '$c') && od -An -tx1 -j18 -N1 \"\$mnt/server\"" | tr -d ' ')
  buildah rm "$c" >/dev/null
  echo "$arch: /server e_machine=0x$machine"
  [ "$machine" = "$want" ] || { echo "wrong binary architecture for $arch" >&2; exit 1; }
}

echo "--- 1. One build per platform ---"
for arch in amd64 arm64; do
  buildah build \
    --format docker \
    --platform "linux/$arch" \
    --tag "localhost/buildah-l3-multiarch:$arch" \
    --file "$APP_DIR/Dockerfile" \
    "$APP_DIR"
done

echo "--- 2. Each image holds a binary for its own architecture ---"
check_binary_arch amd64 3e
check_binary_arch arm64 b7

echo "--- 3. Group them in a manifest list ---"
buildah manifest rm "$MANIFEST" >/dev/null 2>&1 || true
buildah manifest create "$MANIFEST"
buildah manifest add "$MANIFEST" localhost/buildah-l3-multiarch:amd64
buildah manifest add "$MANIFEST" localhost/buildah-l3-multiarch:arm64

echo "--- 4. Inspect the manifest list ---"
buildah manifest inspect "$MANIFEST"
archs=$(buildah manifest inspect "$MANIFEST" | jq -r '[.manifests[].platform.architecture] | sort | join(",")')
echo "architectures in the list: $archs"
[ "$archs" = "amd64,arm64" ] || { echo "expected amd64,arm64" >&2; exit 1; }

echo
echo "Push the whole list to a registry:"
echo "  buildah manifest push --all $MANIFEST docker://registry.example.com/team/app:latest"
echo "=== Done ==="
