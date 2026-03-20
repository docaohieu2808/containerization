#!/usr/bin/env bash
# L3: Podman + systemd — generate and enable user systemd units from containers
# Demonstrates:
#   - podman generate systemd: create unit file from existing container
#   - Install unit to ~/.config/systemd/user/
#   - systemctl --user enable/start/status
#   - loginctl enable-linger (keep services alive after logout)
#
# Run: bash podman-generate-systemd-user-service.sh

set -euo pipefail

CONTAINER_NAME="demo-nginx"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$UNIT_DIR/container-${CONTAINER_NAME}.service"

echo "=== L3: Podman + systemd Integration ==="

# ── 1. Create a container to generate a unit from ────────────────────────────
echo ""
echo "--- 1. Creating container '$CONTAINER_NAME' (stopped) ---"
podman create \
  --name "$CONTAINER_NAME" \
  --publish 8080:80 \
  --restart always \
  nginx:alpine

# ── 2. Generate systemd unit file ────────────────────────────────────────────
echo ""
echo "--- 2. Generating systemd unit file ---"
mkdir -p "$UNIT_DIR"

# --new: unit uses `podman run` (not `podman start`) — container is recreated on start
# --files: write unit to current directory
# Without --new: unit uses `podman start` — container must pre-exist
podman generate systemd \
  --new \
  --name \
  --restart-policy=always \
  "$CONTAINER_NAME" > "$UNIT_FILE"

echo "Unit written to: $UNIT_FILE"
echo ""
cat "$UNIT_FILE"

# ── 3. Enable and start the user service ─────────────────────────────────────
echo ""
echo "--- 3. Enabling and starting user service ---"
systemctl --user daemon-reload
systemctl --user enable --now "container-${CONTAINER_NAME}.service"

# ── 4. Check status ──────────────────────────────────────────────────────────
echo ""
echo "--- 4. Service status ---"
systemctl --user status "container-${CONTAINER_NAME}.service" --no-pager

# ── 5. Enable linger so service survives logout ──────────────────────────────
echo ""
echo "--- 5. Enable linger (service persists after logout) ---"
echo "Run: loginctl enable-linger $USER"
echo "(Skipping actual loginctl call — requires sudo on some systems)"

# ── 6. Useful commands ───────────────────────────────────────────────────────
echo ""
echo "--- Useful commands ---"
echo "  View logs:    journalctl --user -u container-${CONTAINER_NAME}.service -f"
echo "  Stop:         systemctl --user stop container-${CONTAINER_NAME}.service"
echo "  Disable:      systemctl --user disable container-${CONTAINER_NAME}.service"
echo "  Remove unit:  rm $UNIT_FILE && systemctl --user daemon-reload"

# ── Cleanup (comment out to keep service running) ────────────────────────────
echo ""
echo "--- Cleanup ---"
systemctl --user stop    "container-${CONTAINER_NAME}.service" || true
systemctl --user disable "container-${CONTAINER_NAME}.service" || true
rm -f "$UNIT_FILE"
systemctl --user daemon-reload
podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
echo "Cleaned up."
