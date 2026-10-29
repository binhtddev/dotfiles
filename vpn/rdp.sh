#!/usr/bin/env bash
#
# Open / re-attach to the office Windows desktop over the TMA VPN.
#
# - expects the VPN to be up already: nothing here dials it. Connect it on
#   purpose (panel badge, KRunner "TMA VPN — Connect") and it stays up until
#   you disconnect it.
# - reads the password from KWallet (the entry KRDC used), and stores a new one
#   when the old one is rejected
# - xfreerdp with auto-reconnect; retries while the tunnel is still up, keeping
#   fullscreen
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"

RDP_HOST="${RDP_HOST:-192.168.104.117}"
RDP_USER="${RDP_USER:-tdbinh1}"
RDP_DOMAIN="${RDP_DOMAIN:-TMA}"
RDP_WALLET="${RDP_WALLET:-kdewallet}"
RDP_FOLDER="${RDP_FOLDER:-KRDC}"
RDP_ENTRY="${RDP_ENTRY:-rdp://${RDP_USER}@${RDP_HOST}?domain=${RDP_DOMAIN}}"
RETRY_DELAY="${RETRY_DELAY:-5}"

SUBNET_MARKER='192\.168\.104\.'
vpn_is_up() { ip route show table 220 2>/dev/null | grep -q "$SUBNET_MARKER"; }

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "TMA RDP" -i network-vpn "$1"
  else
    kdialog --error "$1" --title "TMA RDP"
  fi
}

read_pass() { kwallet-query -r "$RDP_ENTRY" -f "$RDP_FOLDER" "$RDP_WALLET" 2>/dev/null || true; }
save_pass() { printf '%s' "$1" | kwallet-query -w "$RDP_ENTRY" -f "$RDP_FOLDER" "$RDP_WALLET" >/dev/null 2>&1 || true; }
ask_pass() { kdialog --password "Password for ${RDP_DOMAIN}\\${RDP_USER}@${RDP_HOST}" --title "TMA RDP"; }

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# --set-password: update the KWallet entry and exit (used by the panel menu).
if [ "${1:-}" = "--set-password" ]; then
  pass="$(ask_pass)" || exit 0
  save_pass "$pass"
  kdialog --msgbox "RDP password saved to KWallet." --title "TMA RDP"
  exit 0
fi

# No implicit VPN: connecting the tunnel is an explicit action.
if ! vpn_is_up; then
  notify "The TMA VPN is down. Connect it first (TMA VPN — Connect), then open the desktop again."
  exit 1
fi

pass="$(read_pass)"
if [ -z "$pass" ]; then
  pass="$(ask_pass)" || exit 0
  save_pass "$pass"
fi

while :; do
  printf '%s\n' "$pass" | xfreerdp \
    "/v:${RDP_HOST}" \
    "/u:${RDP_DOMAIN}\\${RDP_USER}" \
    /from-stdin:force /cert:tofu \
    /f +dynamic-resolution +clipboard \
    /sound:sys:pulse /microphone:sys:pulse /audio-mode:redirect \
    +auto-reconnect /auto-reconnect-max-retries:5 /network:auto \
    2>"$log"
  rc=$?

  # 0 = the user closed the window
  [ "$rc" -eq 0 ] && break

  if grep -qE 'ERRCONNECT_(AUTHENTICATION_FAILED|LOGON_FAILURE|PASSWORD_[A-Z_]*|ACCOUNT_[A-Z_]*)' "$log"; then
    pass="$(kdialog --password "Password rejected — enter the new one" --title "TMA RDP")" || break
    save_pass "$pass"
    continue
  fi

  # The tunnel going away is not something a retry can fix (and we do not
  # silently redial it): stop and say so.
  if ! vpn_is_up; then
    notify "The TMA VPN went down — the remote desktop connection was closed."
    break
  fi

  # transport blip on a live tunnel: retry
  sleep "$RETRY_DELAY"
done
