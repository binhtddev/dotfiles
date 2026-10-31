# TMA IPsec VPN (strongSwan + swanctl)

How this machine connects to TMA's internal network (Work At Home Service),
adapted for NixOS from TMA IT's Ubuntu guide
(`Hướng dẫn sử dụng Work At Home Service_Linux.docx`).

Gateway: `qtsc-wah.tma.com.vn` (QTSC). `pn-wah.tma.com.vn` (PN) is reserved for
later — override with `VPN_GATEWAY`.

## How it works

TMA runs a **FortiGate IPsec (IKEv2) VPN with certificate authentication**.
FortiClient on Windows/macOS is only a GUI for the same exchange that
strongSwan performs on Linux — same certificate, same gateway, same protocol:

| TMA guide (Windows) | Here (NixOS) |
|---|---|
| Download `.p12` + choose a password | `vpn/secrets/*.p12` (gitignored) |
| Import Certificate | `openssl pkcs12` → `/etc/swanctl/x509/client.pem` + `/etc/swanctl/private/client.key` |
| Install FortiClient 7.4.3+ | `strongswan` + `swanctl` (`vpn/nixos.nix`) |
| Import Configuration | `/etc/swanctl/tma.conf` (gateway, proposals, subnets) |
| Connect | `swanctl --initiate --child net` |

Two SAs are negotiated:

- **IKE_SA** — mutual certificate authentication with the gateway.
- **CHILD_SA** — the encrypted ESP tunnel, with traffic selectors
  `local_ts === remote_ts`.

The gateway also assigns a **virtual IP** (`vips = 0.0.0.0` in the profile);
that is your identity inside TMA and the source address of your tunnel traffic.
It is added to the Wi‑Fi interface as a `/32` (e.g. `11.11.24.10/32`).

Traffic to `remote_ts` is captured by kernel **xfrm policies** and encrypted;
everything else still uses your normal connection (**split tunnel**).

## Files

| File | Purpose |
|---|---|
| `nixos.nix` | NixOS module: strongSwan + swanctl, includes the local profile |
| `swanctl.conf` | swanctl profile template (no secrets, `__PLACEHOLDER__`s) |
| `setup.sh` | Exports certs from the `.p12`, installs CA chain + profile, loads it |
| `vpn.sh` | `up` / `down` / `toggle` / `status`, launcher-friendly (elevates once) |
| `vpn-root.sh` | root-side helper (swanctl's vici socket is root-only) |
| `rdp.sh` | Open/re-attach the office desktop: KWallet password, retry while the tunnel is up (never dials the VPN) |
| `panel-setup.sh` | `show` / `hide` the `TMA: VPN ● / RDP ●` panel badge |
| `connect.sh` / `disconnect.sh` | Bring the tunnel up / down |
| `certs/` | CA certificates (gitignored, not committed) |
| `secrets/` | the `.p12` client bundle (gitignored, never committed) |

The desktop entries come from `../home/vpn.nix` (Home Manager); `freerdp`,
`kdialog` and the Command Output applet from `../home/plasma.nix`.

## One-time setup

**1. NixOS wiring** — `hosts/atem/configuration.nix` imports it already:

```nix
imports = [ ../../vpn/nixos.nix ];
```

then `sudo nixos-rebuild switch --flake .#atem`. This provides `swanctl`, the
`strongswan-swanctl` unit, and creates `/etc/swanctl/{x509,x509ca,private}` plus
an empty `tma.conf` (so `swanctl --load-all` succeeds before the first setup).

The unit is **not started at boot** (`wantedBy = mkForce [ ]` in `nixos.nix`):
`vpn.sh up` starts `strongswan-swanctl` the first time it is needed, which also
loads `/etc/swanctl/tma.conf` via the unit's `ExecStartPost`. Nothing about the
VPN runs until you ask for it — and boot no longer waits ~6 s on
`NetworkManager-wait-online`, since this unit was its only consumer.

**2. CA certificates** (public material, from TMA's "Certificate" zip):

```sh
mkdir -p vpn/certs
# CA_Cert_5.cer, gsgccr6alphasslca2025.crt, "GlobalSign Root CA - R6.crt"
```

**3. Client bundle** next to the scripts (gitignored):

```sh
install -m 600 -D ~/Downloads/setup-vpn-tma/tdbinh1_vpn.p12 \
  vpn/secrets/tdbinh1_vpn.p12
```

**4. Install certs + profile** (prompts for the `.p12` password):

```sh
sudo VPN_USER=tdbinh1 VPN_EMAIL=tdbinh1@tma.com.vn VPN_OU=ITsystem \
     VPN_SUBNET=192.168.104.0/22 ./vpn/setup.sh
```

Overridable: `VPN_USER`, `VPN_EMAIL`, `VPN_OU`, `VPN_GATEWAY`, `VPN_SUBNET`,
`P12`. The script prints the certificate subject — `CN`/`emailAddress` must
match *your* certificate (the guide's sample says `CN=vvthinh`).

## Connect / disconnect

```sh
sudo ./vpn/connect.sh       # or: ./vpn/vpn.sh up
sudo ./vpn/disconnect.sh    # or: ./vpn/vpn.sh down
./vpn/vpn.sh status         # up | down  (elevates once)
```

Or from **KRunner** (Alt+Space): **TMA VPN — Connect / Disconnect / Toggle**
(`home/vpn.nix`). Terminal use goes through `sudo`, launcher use through
`/run/wrappers/bin/pkexec` + the Plasma polkit agent.

## Reaching machines inside TMA

Once the tunnel is up, treat the internal hosts as a normal LAN.

```sh
sudo swanctl --list-sas           # find the TS line and your VIP
#   CHILD_SA net{2} … TS 11.11.24.10/32 === 192.168.104.0/22
```

If the TS is right, traffic to that range is encrypted and sourced from the
VIP. Check reachability with a **TCP probe** — many corporate hosts drop ICMP,
so `ping` loss alone proves nothing:

```sh
nc -vz -w3 192.168.104.117 22 3389 443
```

### RDP (the office Windows box)

`192.168.104.117:3389` is a Windows machine with RDP enabled. Use `rdp.sh` —
it expects the tunnel to be up already (it never dials or tears down the VPN),
re-attaches on flaky links, and stops with a notification if the tunnel is gone:

```sh
./vpn/vpn.sh up       # once, on purpose (or: TMA VPN — Connect in KRunner)
./vpn/rdp.sh          # or: right-click the badge → "Open office desktop"
```

What it does:

- password from **KWallet** (folder `KRDC`, entry
  `rdp://tdbinh1@192.168.104.117?domain=TMA`). Missing → `kdialog` prompt, then
  saved to the same entry;
- if the password is rejected (`ERRCONNECT_LOGON_FAILURE` /
  `AUTHENTICATION_FAILED` / `PASSWORD_EXPIRED` / `ACCOUNT_*`) it prompts for the
  new one and **overwrites the KWallet entry**, then retries;
- anything else (transport blip) → waits 5 s and retries, but only while the
  tunnel is still up; if the VPN went down it notifies and stops (nothing
  re-dials it behind your back);
- `xfreerdp` with `+auto-reconnect /auto-reconnect-max-retries:5`, `/f` keeps
  fullscreen across reconnects;
- **audio both ways** via PulseAudio/PipeWire: `/sound:sys:pulse` (remote sound
  to your speakers) and `/microphone:sys:pulse` (your mic into the session),
  with `/audio-mode:redirect`;
- exit 0 (you closed the window) ends it; the tunnel stays up until you
  disconnect it.

Equivalent raw command (no retry/credential handling):

```sh
xfreerdp /v:192.168.104.117 /u:'TMA\tdbinh1' /f +dynamic-resolution +clipboard \
  +auto-reconnect /auto-reconnect-max-retries:0 /cert:tofu
```

### Panel badge

`./vpn/panel-setup.sh` adds the small QML applet in `home/plasma-tma`
(`org.binhtd.tma`) to the first panel — just before the system tray — and
removes the old Command Output badges. `./vpn/panel-setup.sh hide` removes it
again, so it exists only when you put it there. It renders as two aligned lines
(a `GridLayout`, so no monospace font is needed):

```
TMA: VPN ●
     RDP ○
```

| Action | Result |
|---|---|
| left click | toggle the VPN |
| right click | Plasma's applet menu: **VPN: connect**, **VPN: disconnect**, **Open office desktop**, **Update RDP password** |
| hover | tooltip with the current VPN/RDP state |

Status, polled every 3 s without privileges:

- `VPN ●/○` — charon's route table (`ip route show table 220`)
- `RDP ●/○` — an `xfreerdp` process (`pgrep -x xfreerdp`)

While both are idle the badge collapses to zero width, so it only occupies the
panel while the tunnel is up or a session is open; it reappears by itself as
soon as either is in use. Right-click → **Configure** → *Hide when the VPN is
down and no session is running* turns that off. Nothing dials the VPN on its
own: the swanctl child has `start_action = none`, and `rdp.sh` refuses to start
without a tunnel.

The menu actions run as root through `pkexec`; `vpn/nixos.nix` adds a polkit
rule so `wheel` can run `vpn.sh` without a password prompt. `Update RDP
password` runs `rdp.sh --set-password`, which prompts and overwrites the
KWallet entry.

Two unrelated panel preferences live in their own script,
`plasma/setup.sh` (run once, and again with `--force` if the panel or the
system tray is recreated):

- icons-only task manager: `groupedTaskVisualization = 1`, so clicking a
  grouped icon shows the window previews instead of cycling (`0` cycles,
  `2` runs Present Windows, `3` shows a textual list)
- system tray battery: `showPercentage = true`, the charge badge on the icon

They are keyed by containment/applet ids that plasmashell assigns at runtime,
so the script finds them by plugin name. plasma-manager cannot declare them:
its `configFile` for `plasma-org.kde.plasma.desktop-appletsrc` is typed
(`value`/`immutable`/`persistent` per containment) and applet configs are
nested applets, not panel widgets.

### SSH / web

```sh
ssh user@192.168.104.117        # if the box also runs sshd
curl -k https://192.168.104.117
```

### DNS

The profile pushes **no DNS**, so only names that resolve publicly work.
Internal-only names need the VPN's DNS server (ask IT) added to
`/etc/resolv.conf` or `networking.dns`/systemd-resolved, or an `/etc/hosts`
entry.

## Verification

```sh
sudo swanctl --list-conns
sudo swanctl --list-sas          # IKE_SA ESTABLISHED, CHILD_SA INSTALLED, TS …
sudo swanctl --list-creds
sudo ip xfrm policy              # src <VIP>/32 dst <subnet>/mask dir out
ip route show table 220          # charon's routes
journalctl -u strongswan-swanctl -f
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| KRunner entry does nothing, journal says `pkexec must be setuid root` | used the store `pkexec`, not the NixOS setuid wrapper | entries use `/run/wrappers/bin/pkexec` (already fixed in `home/vpn.nix`) |
| Only one address reachable / `.117` times out | `remote_ts` is a bare address → `/32` (single host) | give `remote_ts` a mask, e.g. `192.168.104.0/22` |
| `TS_UNACCEPTABLE` / no CHILD_SA | selector rejected by the gateway | try a narrower mask (`/23`, `/24`) |
| `status`/`toggle` always says "down" | `swanctl` needs root for `/run/charon.vici` | `vpn-root.sh` runs the check as root after one elevation |
| `ping` fails but the service works | host filters ICMP | test the TCP port with `nc -vz` |
| `client bundle not found` | `.p12` not in `vpn/secrets/` | copy it there, or pass `P12=/path` |
| Connection drops after suspend/resume | IKE SA died | toggle again |
| Session shows a failed `app-tma-vpn-…` unit | an earlier failed launch | `systemctl --user reset-failed` |

## Notes from TMA's guide

- **`CN` / `emailAddress`** — must be your own DN (`VPN_USER`/`VPN_EMAIL`/`VPN_OU`).
- **`remote_ts`** (`VPN_SUBNET`) — the group subnet **with a mask**; currently
  `192.168.104.0/22`. A bare address would be a `/32`. The gateway is
  permissive, so tighten this to whatever `swanctl --list-sas` reports.
- **Gateway** — `qtsc-wah.tma.com.vn` (QTSC); `pn-wah` for later.

## Credentials

| Value | Sensitivity | Where it lives |
|---|---|---|
| Client private key (`client.key`, from the `.p12`) | **secret**, long-lived | `/etc/swanctl/private/client.key`, 600 root |
| `.p12` container password | secret, **one-time** | typed into `setup.sh`; never stored |
| CA certs, profile, DN | public / PII-ish | `vpn/certs/`, `/etc/swanctl/tma.conf` |

The `.p12` lives in `vpn/secrets/` (gitignored via `secrets/` and `*.p12`) so
paths are stable and independent of `$HOME`/sudo. It is still a private key
inside the repo directory — avoid `git add -f`, `git archive` of the worktree,
or copying the folder around.

For a stricter setup, move the long-lived key into a secrets manager:

1. **agenix** — age-encrypted file in the repo, decrypted at activation to
   `/etc/swanctl/private/client.key` with `mode = "600"`.
2. **sops-nix** — one YAML/JSON for several keys, per-host sharing, CI.
3. **systemd-creds** — no extra flake; encrypt with the host key/TPM and load
   with `LoadCredential` (tied to this machine).

## Maintenance

- The certificate is valid **365 days**; regenerate it on
  `https://ca-vpn.tma.com.vn` (internal) and re-run `setup.sh`.
- The `.p12` password cannot be recovered — revoke + regenerate if lost.
- Nix flakes only see **git-tracked** files: `git add vpn/ home/vpn.nix`
  before a real `nixos-rebuild` / `home-manager switch` (`vpn/certs/` and
  `vpn/secrets/` stay ignored).
