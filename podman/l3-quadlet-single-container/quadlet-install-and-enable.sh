#!/usr/bin/env bash
# L3: validate, install and start a Quadlet unit under `systemctl --user`.
#   1. quadlet -dryrun        shows the systemd unit Quadlet generates, fails on bad syntax
#   2. podman quadlet install copies the file to the right directory (Podman 5.6+)
#   3. systemctl --user start runs it; we wait for the container to be healthy
#   4. cleanup: podman quadlet rm (KEEP=1 leaves it running)
#
# Needs a user systemd session. For services that survive logout:
#   loginctl enable-linger "$USER"
#
# Run: bash quadlet-install-and-enable.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_FILE=hello-web.container
SERVICE=hello-web.service
PORT=18083

QUADLET=""
for candidate in /usr/libexec/podman/quadlet /usr/lib/podman/quadlet; do
  if [ -x "$candidate" ]; then QUADLET=$candidate; break; fi
done
[ -n "$QUADLET" ] || { echo "quadlet binary not found (is Podman 4.4+ installed?)" >&2; exit 1; }

cleanup() {
  if [ "${KEEP:-0}" != 1 ]; then
    systemctl --user stop "$SERVICE" >/dev/null 2>&1 || true
    podman quadlet rm "$UNIT_FILE" >/dev/null 2>&1 || true
    systemctl --user daemon-reload || true
  fi
}
trap cleanup EXIT

echo "=== L3: Quadlet single container ==="
podman --version

echo "--- 1. Dry run: the unit Quadlet generates ---"
QUADLET_UNIT_DIRS="$SCRIPT_DIR" "$QUADLET" -dryrun -user | sed -n '/^---hello-web.service---/,/^$/p'
# -dryrun exits non-zero if any file in the directory is invalid.
QUADLET_UNIT_DIRS="$SCRIPT_DIR" "$QUADLET" -dryrun -user >/dev/null

echo "--- 2. Install ---"
podman quadlet install "$SCRIPT_DIR/$UNIT_FILE"
systemctl --user daemon-reload
podman quadlet list

echo "--- 3. Start and wait for healthy ---"
systemctl --user start "$SERVICE"
for _ in $(seq 1 60); do
  status=$(podman inspect --format '{{.State.Health.Status}}' hello-web 2>/dev/null || true)
  [ "$status" = "healthy" ] && break
  sleep 2
done
echo "container health: ${status:-unknown}"
[ "${status:-}" = "healthy" ] || { journalctl --user -u "$SERVICE" --no-pager | tail -30; exit 1; }
curl -fsS "http://127.0.0.1:${PORT}/" | grep -q "Welcome to nginx"
echo "GET http://127.0.0.1:${PORT}/ -> nginx welcome page"
systemctl --user is-active "$SERVICE"

echo "=== Done. Manage with: systemctl --user {status,stop,restart} $SERVICE ==="
