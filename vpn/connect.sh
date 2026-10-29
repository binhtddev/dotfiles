#!/usr/bin/env bash
# Bring the TMA IPsec tunnel up.
set -euo pipefail

# pkexec resets PATH to a non-Nix default, so make the system profile explicit.
# swanctl lives in sbin, which is not on the default user PATH.
export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin:$PATH"

[ "$(id -u)" -eq 0 ] || exec sudo bash "$0" "$@"

swanctl --load-creds
swanctl --load-conns
swanctl --initiate --child net
swanctl --list-sas
