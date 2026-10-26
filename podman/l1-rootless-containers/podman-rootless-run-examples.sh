#!/usr/bin/env bash
# L1: rootless Podman. No daemon, no root, no docker group.
# Demonstrates (and asserts, so a broken setup fails loudly):
#   1. Podman really runs rootless
#   2. user namespaces: container root is YOU on the host; --userns=keep-id keeps your uid
#   3. where rootless storage lives
#   4. rootless networking with pasta (the only rootless network backend in Podman 6;
#      slirp4netns was removed in 6.0) and a published port
#
# Prerequisites: a current Podman (6.x; 5.x also works), subuid/subgid entries for your user:
#   grep "$USER" /etc/subuid /etc/subgid
#   sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
#
# Run: bash podman-rootless-run-examples.sh
set -euo pipefail

ALPINE=docker.io/library/alpine:3.24.3
NGINX=docker.io/library/nginx:1.30.6-alpine3.24-slim
WEB_PORT=${WEB_PORT:-18081}
WORKDIR=$(mktemp -d)
cleanup() {
  podman rm -f l1-rootless-web >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "=== L1: rootless Podman ==="
podman --version

echo
echo "--- 1. Podman is rootless ---"
rootless=$(podman info --format '{{.Host.Security.Rootless}}')
echo "rootless: $rootless"
[ "$rootless" = "true" ] || { echo "expected a rootless Podman (run as a normal user)" >&2; exit 1; }

echo
echo "--- 2. User namespaces ---"
# Default mapping: uid 0 inside the container is your own uid on the host.
inside=$(podman run --rm "$ALPINE" id -u)
echo "default userns:   uid inside container = $inside"
[ "$inside" = "0" ]
# keep-id: the container user has the same uid as you, so bind-mounted files
# are owned by you on both sides.
keep=$(podman run --rm --userns=keep-id "$ALPINE" id -u)
echo "--userns=keep-id: uid inside container = $keep (host uid is $(id -u))"
[ "$keep" = "$(id -u)" ]
podman run --rm --userns=keep-id -v "$WORKDIR:/data:Z" "$ALPINE" touch /data/created-in-container
owner=$(stat -c %u "$WORKDIR/created-in-container")
echo "file created in the container is owned on the host by uid $owner"
[ "$owner" = "$(id -u)" ]

echo
echo "--- 3. Rootless storage lives under your home directory ---"
graphroot=$(podman info --format '{{.Store.GraphRoot}}')
echo "graph root: $graphroot"
case "$graphroot" in "$HOME"/*) ;; *) echo "graph root is not under \$HOME" >&2; exit 1 ;; esac

echo
echo "--- 4. Rootless networking: pasta + a published port ---"
podman run -d --name l1-rootless-web --network=pasta -p "${WEB_PORT}:80" --entrypoint sh "$NGINX" \
  -c 'echo hello-from-pasta > /usr/share/nginx/html/index.html && exec nginx -g "daemon off;"'
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${WEB_PORT}/" 2>/dev/null | grep -q hello-from-pasta; then
    reached=1
    break
  fi
  sleep 1
done
if [ "${reached:-0}" != 1 ]; then
  echo "container not reachable on port ${WEB_PORT}" >&2
  podman ps -a >&2
  podman logs l1-rootless-web >&2 || true
  exit 1
fi
echo "GET http://127.0.0.1:${WEB_PORT}/ -> hello-from-pasta"
echo "(ports below 1024 need: sysctl net.ipv4.ip_unprivileged_port_start=80)"

echo
echo "--- 5. You only see your own containers ---"
podman ps

echo
echo "=== Done. No sudo was used ==="
