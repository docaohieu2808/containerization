#!/usr/bin/env bash
# L4: Install Quadlet files and activate via systemd
# Copies .container, .pod, .volume files to the correct location and reloads systemd
#
# Run: bash quadlet-install-and-enable.sh

set -euo pipefail

QUADLET_DIR="$HOME/.config/containers/systemd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== L4: Quadlet Install & Enable ==="

# ── 1. Create quadlet directory ───────────────────────────────────────────────
mkdir -p "$QUADLET_DIR"

# ── 2. Copy quadlet files ─────────────────────────────────────────────────────
echo "Copying quadlet files to $QUADLET_DIR ..."
cp "$SCRIPT_DIR/nginx-webserver.container"      "$QUADLET_DIR/"
cp "$SCRIPT_DIR/nginx-webserver-data.volume"    "$QUADLET_DIR/"
cp "$SCRIPT_DIR/app-with-db.pod"                "$QUADLET_DIR/"

# ── 3. Reload systemd to trigger Quadlet generator ───────────────────────────
echo "Reloading systemd user daemon (Quadlet generates units now) ..."
systemctl --user daemon-reload

# ── 4. List generated units ───────────────────────────────────────────────────
echo ""
echo "--- Generated units from Quadlet ---"
systemctl --user list-unit-files | grep -E "nginx-webserver|app-with-db" || echo "(none found — check quadlet files)"

# ── 5. Start the nginx service ────────────────────────────────────────────────
echo ""
echo "--- Starting nginx-webserver.service ---"
systemctl --user start nginx-webserver.service
systemctl --user status nginx-webserver.service --no-pager

echo ""
echo "=== Quadlet services active. Manage with: systemctl --user {start,stop,status} nginx-webserver.service ==="
