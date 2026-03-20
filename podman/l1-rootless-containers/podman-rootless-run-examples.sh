#!/usr/bin/env bash
# L1: Rootless Podman — run containers without root privileges
# Demonstrates:
#   - Basic rootless run (no sudo required)
#   - --userns=keep-id: map host UID into container so volume mounts work
#   - User storage config (no /var/lib/docker, uses ~/.local/share/containers)
#   - Network in rootless mode (slirp4netns or pasta)
#
# Prerequisites: Podman 4.x installed, subuid/subgid entries for your user
#   Check: grep $USER /etc/subuid /etc/subgid
#   If missing: sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER

set -euo pipefail

echo "=== L1: Rootless Podman Examples ==="

# ── 1. Basic rootless container run ─────────────────────────────────────────
echo ""
echo "--- 1. Basic rootless container (no sudo) ---"
# Runs as your UID inside the container's user namespace
podman run --rm alpine:3.19 id
# Expected: uid=0(root) gid=0(root) — inside namespace, but host sees your UID

# ── 2. --userns=keep-id — preserve host UID in container ────────────────────
echo ""
echo "--- 2. --userns=keep-id: host UID mapped into container ---"
# Without keep-id: files created in volume are owned by root on host
# With keep-id:    files created in volume are owned by YOU on host
podman run --rm \
  --userns=keep-id \
  -v /tmp/podman-test:/data:Z \
  alpine:3.19 \
  sh -c "touch /data/testfile && ls -la /data/testfile"
# :Z relabels the volume for SELinux (safe to use on non-SELinux systems too)

# ── 3. Storage configuration overview ───────────────────────────────────────
echo ""
echo "--- 3. Rootless storage locations ---"
echo "Images:     ~/.local/share/containers/storage/overlay-images/"
echo "Containers: ~/.local/share/containers/storage/overlay-containers/"
echo "Config:     ~/.config/containers/storage.conf"
echo ""
echo "Current storage info:"
podman info --format '{{.Store.GraphRoot}}'

# ── 4. Rootless networking (slirp4netns / pasta) ─────────────────────────────
echo ""
echo "--- 4. Rootless port mapping (unprivileged ports only, >1024 without sysctl) ---"
# In rootless mode, ports < 1024 require: sysctl net.ipv4.ip_unprivileged_port_start=80
# This example uses port 8080 (always allowed unprivileged)
echo "Start: podman run -d --rm -p 8080:3000 --name demo-node node:20-alpine node -e \"require('http').createServer((_,r)=>r.end('ok')).listen(3000)\""
echo "(Skipping actual long-running container start in this demo script)"

# ── 5. Show running rootless containers ──────────────────────────────────────
echo ""
echo "--- 5. List containers (rootless — only YOUR containers) ---"
podman ps -a

echo ""
echo "=== Done. All commands ran without sudo ==="
