#!/usr/bin/env bash
# Tear the TMA IPsec tunnel down.
set -euo pipefail

# pkexec resets PATH to a non-Nix default, so make the system profile explicit.
# swanctl lives in sbin, which is not on the default user PATH.
export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin:$PATH"

[ "$(id -u)" -eq 0 ] || exec sudo bash "$0" "$@"

swanctl --terminate --ike fortigate
swanctl --list-sas
