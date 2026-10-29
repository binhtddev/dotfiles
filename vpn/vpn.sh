#!/usr/bin/env bash
#
# TMA IPsec VPN control, launcher-friendly.
#
#   vpn.sh up | down | toggle | status
#
# Elevates exactly once (sudo in a terminal, pkexec/polkit from a .desktop /
# KRunner entry) and delegates to vpn-root.sh.
#
set -euo pipefail

# wrappers first: the setuid pkexec/sudo wrappers live in /run/wrappers/bin,
# while /run/current-system/sw/bin/pkexec is a non-setuid store symlink.
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="${1:-toggle}"

BASH_BIN="${BASH:-/run/current-system/sw/bin/bash}"
PKEXEC_BIN=/run/wrappers/bin/pkexec
[ -x "$PKEXEC_BIN" ] || PKEXEC_BIN="$(command -v pkexec 2>/dev/null || true)"

case "$CMD" in
  up | down | toggle | status) ;;
  *)
    echo "usage: $(basename "$0") {up|down|toggle|status}" >&2
    exit 2
    ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  exec "$BASH_BIN" "$HERE/vpn-root.sh" "$CMD"
elif [ -t 0 ] && command -v sudo >/dev/null 2>&1; then
  exec sudo "$BASH_BIN" "$HERE/vpn-root.sh" "$CMD"
elif [ -x "$PKEXEC_BIN" ]; then
  exec "$PKEXEC_BIN" "$BASH_BIN" "$HERE/vpn-root.sh" "$CMD"
else
  echo "error: neither sudo nor a setuid pkexec is available" >&2
  exit 1
fi
