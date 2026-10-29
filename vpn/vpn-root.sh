#!/usr/bin/env bash
#
# Root-side VPN actions. vpn.sh elevates once and delegates here.
#
# swanctl talks to charon over /run/charon.vici, which is root-only, so the
# state check has to happen here too (otherwise "toggle" would never disconnect).
#
set -euo pipefail

export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="${1:-status}"

[ "$(id -u)" -eq 0 ] || {
  echo "vpn-root.sh must run as root (use vpn.sh)" >&2
  exit 1
}

is_up() { swanctl --list-sas 2>/dev/null | grep -qE 'ESTABLISHED|INSTALLED'; }

case "$CMD" in
  up) exec "$HERE/connect.sh" ;;
  down) exec "$HERE/disconnect.sh" ;;
  toggle)
    if is_up; then
      exec "$HERE/disconnect.sh"
    else
      exec "$HERE/connect.sh"
    fi
    ;;
  status)
    if is_up; then echo "up"; else echo "down"; fi
    ;;
  *)
    echo "usage: $(basename "$0") {up|down|toggle|status}" >&2
    exit 2
    ;;
esac
