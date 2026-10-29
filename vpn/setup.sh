#!/usr/bin/env bash
#
# TMA IPsec VPN (FortiGate) setup for NixOS / strongSwan-swanctl.
#
#   sudo ./setup.sh
#
# It exports the client certificate + key from the PKCS#12 bundle that TMA IT
# issued, installs the CA chain, renders the swanctl profile and loads it.
# Idempotent: safe to re-run (e.g. after the certificate is rotated).
#
set -euo pipefail

# swanctl lives in sbin, which is not on the default user PATH.
export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:/run/wrappers/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Edit these, or export them before running the script.
# ---------------------------------------------------------------------------
VPN_USER="${VPN_USER:-tdbinh1}"
VPN_EMAIL="${VPN_EMAIL:-tdbinh1@tma.com.vn}"
VPN_OU="${VPN_OU:-ITsystem}"
# Current office is QTSC (qtsc-wah). pn-wah.tma.com.vn is kept for the future.
VPN_GATEWAY="${VPN_GATEWAY:-qtsc-wah.tma.com.vn}"
# remote_ts: the group's subnet (needs a mask — a bare address is a /32).
# /22 is the widest block that keeps 192.168.104.0 as the network address and
# contains .117; tighten it once `swanctl --list-sas` shows what the gateway
# actually accepts.
VPN_SUBNET="${VPN_SUBNET:-192.168.104.0/22}"
# Kept next to the scripts and gitignored (vpn/.gitignore: secrets/, *.p12).
P12="${P12:-$HERE/secrets/tdbinh1_vpn.p12}"

# ---------------------------------------------------------------------------
SWANCTL_DIR="${SWANCTL_DIR:-/etc/swanctl}"
CONF="$SWANCTL_DIR/tma.conf"

die() {
  echo "error: $*" >&2
  exit 1
}

# Re-exec as root, keeping the tunables we were given.
if [ "$(id -u)" -ne 0 ]; then
  exec sudo --preserve-env=P12,VPN_USER,VPN_EMAIL,VPN_OU,VPN_GATEWAY,VPN_SUBNET \
    bash "$0" "$@"
fi

# openssl is not in the system profile by default; fall back to nix.
ossl() {
  if command -v openssl >/dev/null 2>&1; then
    openssl "$@"
  else
    nix shell nixpkgs#openssl -c openssl "$@"
  fi
}

command -v swanctl >/dev/null 2>&1 ||
  die "swanctl not on PATH. Enable services.strongswan-swanctl (see vpn/nixos.nix) and rebuild first."

[ -f "$P12" ] || die "client bundle not found: $P12
  copy it from ~/Downloads/setup-vpn-tma/*.p12 into $HERE/secrets/
  (or set P12=/path/to/file.p12)"
[ -f "$HERE/swanctl.conf" ] || die "missing $HERE/swanctl.conf"

read -rsp "PKCS#12 password for $(basename "$P12"): " P12PASS
echo
[ -n "$P12PASS" ] || die "empty password"

echo "==> installing directories"
install -d -m 755 "$SWANCTL_DIR"/{x509,x509ca,private}
chmod 700 "$SWANCTL_DIR/private"

echo "==> exporting client certificate and key"
# TMA's guide uses `-legacy`; retry with it if the bundle uses old PKCS#12 crypto.
export_from_p12() {
  local out="$1"
  shift
  if ! ossl pkcs12 -in "$P12" "$@" -passin "pass:$P12PASS" -out "$out" 2>/dev/null; then
    echo "note: retrying export with -legacy (older PKCS#12 encryption)"
    ossl pkcs12 -legacy -in "$P12" "$@" -passin "pass:$P12PASS" -out "$out"
  fi
}
export_from_p12 "$SWANCTL_DIR/x509/client.pem" -clcerts -nokeys
export_from_p12 "$SWANCTL_DIR/private/client.key" -nocerts -nodes
chmod 644 "$SWANCTL_DIR/x509/client.pem"
chmod 600 "$SWANCTL_DIR/private/client.key"

echo "==> installing CA certificates"
shopt -s nullglob
cas=("$HERE"/certs/*)
[ "${#cas[@]}" -gt 0 ] || die "no CA certificates in $HERE/certs/ (copy the ones from the Certificate zip)"

for f in "${cas[@]}"; do
  case "$f" in
    *.cer | *.crt | *.pem) install -m 644 "$f" "$SWANCTL_DIR/x509ca/" ;;
    *) continue ;;
  esac
done

echo "==> rendering swanctl profile"
local_id="DC=vn,DC=com,DC=tma,OU=$VPN_OU,CN=$VPN_USER,emailAddress=$VPN_EMAIL"
sed \
  -e "s|__GATEWAY__|$VPN_GATEWAY|g" \
  -e "s|__LOCAL_ID__|$local_id|g" \
  -e "s|__REMOTE_TS__|$VPN_SUBNET|g" \
  "$HERE/swanctl.conf" >"$CONF"
chmod 600 "$CONF"

# If we are not the module-managed file, make sure swanctl.conf loads ours.
if [ -L "$SWANCTL_DIR/swanctl.conf" ]; then
  echo "note: $SWANCTL_DIR/swanctl.conf is NixOS-managed (nix store)."
  echo "      it must contain: services.strongswan-swanctl.includes = [ \"$CONF\" ];"
elif [ -f "$SWANCTL_DIR/swanctl.conf" ] && ! grep -qs "include.*$CONF" "$SWANCTL_DIR/swanctl.conf"; then
  printf '\ninclude %s\n' "$CONF" >>"$SWANCTL_DIR/swanctl.conf"
fi

echo "==> verifying"
ossl x509 -in "$SWANCTL_DIR/x509/client.pem" -noout -subject -issuer -dates
swanctl --load-creds
swanctl --load-conns
swanctl --list-conns

cat <<EOF

Done. Connect with:
    sudo ./connect.sh

If the connection fails, check the journal:
    journalctl -u strongswan-swanctl -f
EOF
