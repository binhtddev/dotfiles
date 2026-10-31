#!/usr/bin/env bash
#
# Plasma desktop configuration — the whole thing, in one imperative place.
#
# Why a script and not nix: applet state and theme application are runtime
# state that KDE owns (~/.config/*rc plus the containment tree), the applet
# settings are keyed by ids plasmashell assigns, and none of that can be
# declared without a tool that rewrites the files behind your back. Everything
# you would click through System Settings is written here instead.
#
#   ./plasma/setup.sh            apply once (no-op while the lock exists)
#   ./plasma/setup.sh --force    apply again, even if the lock exists
#   ./plasma/setup.sh --check    read every value back, report mismatches
#   ./plasma/setup.sh --dump     print the current value of every managed key
#
# The lock is an empty file: its existence means "already applied". Delete it
# (or use --force) after a Plasma upgrade, a theme redesign, or a panel/tray
# recreation.
#
# Nothing here needs root. System-level configuration (SDDM, services, kernel
# parameters) belongs in nixos/*.nix and `nixos-rebuild`; a rebuild would
# overwrite anything written by hand to /etc anyway.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK="${XDG_STATE_HOME:-$HOME/.local/state}/plasma/setup.lock"
RC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

LOOKANDFEEL="com.github.binhtd.dracutux"
PLASMA_STYLE="Dracutux"
COLOR_SCHEME="Dracutux"
CURSOR_THEME="breeze_cursors"
CURSOR_SIZE="24"
ICON_THEME="Dracutux"
WALLPAPER="$HOME/.local/share/wallpapers/background.svg"
CHANGEICONS="/run/current-system/sw/libexec/plasma-changeicons"

# file|group|subgroup|key|value   (empty subgroup = flat group)
# shellcheck disable=SC2016
read -r -d '' TABLE <<'EOF' || true
# file|group|subgroup|key|value   (empty subgroup = flat group)
# power: suspend after 20 min, screen off after 10 min, lid -> hibernate when low
powerdevilrc|AC|Display|TurnOffDisplayIdleTimeoutSec|600
powerdevilrc|AC|Display|TurnOffDisplayIdleTimeoutWhenLockedSec|0
powerdevilrc|AC|SuspendAndShutdown|AutoSuspendAction|1
powerdevilrc|AC|SuspendAndShutdown|AutoSuspendIdleTimeoutSec|1200
powerdevilrc|Battery|Display|TurnOffDisplayIdleTimeoutSec|600
powerdevilrc|Battery|Display|TurnOffDisplayIdleTimeoutWhenLockedSec|0
powerdevilrc|Battery|SuspendAndShutdown|AutoSuspendAction|1
powerdevilrc|Battery|SuspendAndShutdown|AutoSuspendIdleTimeoutSec|1200
powerdevilrc|LowBattery|Display|TurnOffDisplayIdleTimeoutSec|600
powerdevilrc|LowBattery|SuspendAndShutdown|AutoSuspendAction|1
powerdevilrc|LowBattery|SuspendAndShutdown|AutoSuspendIdleTimeoutSec|1200
powerdevilrc|LowBattery|SuspendAndShutdown|LidAction|2
# kwin: no corner barriers, magic lamp + wobbly, constant night light, fcitx
kwinrc|EdgeBarrier||EdgeBarrier|0
kwinrc|EdgeBarrier||CornerBarrier|false
kwinrc|Plugins||magiclampEnabled|true
kwinrc|Plugins||squashEnabled|false
kwinrc|Plugins||wobblywindowsEnabled|true
kwinrc|NightColor||Active|true
kwinrc|NightColor||Mode|Constant
kwinrc|NightColor||NightTemperature|4500
kwinrc|Wayland||InputMethod|/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop
kwinrc|Wayland||VirtualKeyboardEnabled|true
# decoration: Aurorae v2 ignores the theme rc's buttons, so set them here
kwinrc|org.kde.kdecoration2||library|org.kde.kwin.aurorae
kwinrc|org.kde.kdecoration2||theme|__aurorae__svg__Dracutux
kwinrc|org.kde.kdecoration2||BorderSize|Normal
kwinrc|org.kde.kdecoration2||ButtonsOnLeft|
kwinrc|org.kde.kdecoration2||ButtonsOnRight|IAX
# style, colours, icons, cursor
kdeglobals|KDE||widgetStyle|kvantum
kdeglobals|KDE||LookAndFeelPackage|com.github.binhtd.dracutux
kdeglobals|General||ColorScheme|Dracutux
kdeglobals|Icons||Theme|Dracutux
plasmarc|Theme||name|Dracutux
kcminputrc|Mouse||cursorSize|24
kcminputrc|Libinput/Defaults/Touchpad||NaturalScroll|true
# screen locker
kscreenlockerrc|Daemon||LockOnResume|true
kscreenlockerrc|Daemon||Timeout|10
# kded modules that clash with declarative config or log errors
kded6rc|Module-gtkconfig||autoload|false
kded6rc|Module-oom-notifier||autoload|false
kded6rc|Module-plasma-session-shortcuts||autoload|false
kded6rc|Module-wpad-detector||autoload|false
# Kvantum (KDE writes the lowercase key; Kvantum's own is "Theme")
Kvantum/kvantum.kvconfig|General||theme|Dracutux
# KWin starts fcitx5; mask the autostart entry that would start a second one
autostart/org.fcitx.Fcitx5.desktop|Desktop Entry||Type|Application
autostart/org.fcitx.Fcitx5.desktop|Desktop Entry||Name|Fcitx 5
autostart/org.fcitx.Fcitx5.desktop|Desktop Entry||Hidden|true
EOF

# KConfig nests groups as [a][b]; a path "a/b" becomes --group a --group b
kv_groups() {
  local -a args=()
  local IFS=/
  local part
  for part in $1; do args+=(--group "$part"); done
  printf '%s\0' "${args[@]}"
}

kv_read() { # file group-path key
  local -a args=()
  mapfile -d '' -t args < <(kv_groups "$2")
  kreadconfig6 --file "$1" "${args[@]}" --key "$3"
}

kv_write() { # file group-path key value
  local -a args=()
  mapfile -d '' -t args < <(kv_groups "$2")
  kwriteconfig6 --file "$1" "${args[@]}" --key "$3" "$4"
}

have_session() {
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] &&
    systemctl --user is-active --quiet plasma-plasmashell.service
}

js() {
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell \
    evaluateScript s "$1" 2>/dev/null | sed -n 's/^s "\(.*\)"$/\1/p'
}

dump_table() {
  local file group sub key value
  while IFS='|' read -r file group sub key value; do
    case "${file:-}" in '' | '#'*) continue ;; esac
    printf '%-28s %-24s %-44s = %s\n' "$file" "$group${sub:+/$sub}" "$key" \
      "$(kv_read "$file" "$group${sub:+/$sub}" "$key")"
  done <<<"$TABLE"
}

check_table() {
  local file group sub key value current bad=0
  while IFS='|' read -r file group sub key value; do
    case "${file:-}" in '' | '#'*) continue ;; esac
    current="$(kv_read "$file" "$group${sub:+/$sub}" "$key")"
    if [ "$current" != "$value" ]; then
      printf 'MISMATCH %s [%s%s] %s: %q (want %q)\n' \
        "$file" "$group" "${sub:+/$sub}" "$key" "$current" "$value"
      bad=1
    fi
  done <<<"$TABLE"

  # values applied by the plasma-apply-* tools rather than kv_write
  for tuple in \
    "kdeglobals|KDE|LookAndFeelPackage|$LOOKANDFEEL" \
    "kdeglobals|General|ColorScheme|$COLOR_SCHEME" \
    "kdeglobals|Icons|Theme|$ICON_THEME" \
    "plasmarc|Theme|name|$PLASMA_STYLE"; do
    IFS='|' read -r file group key value <<<"$tuple"
    current="$(kv_read "$file" "$group" "$key")"
    if [ "$current" != "$value" ]; then
      printf 'MISMATCH %s [%s] %s: %q (want %q)\n' "$file" "$group" "$key" "$current" "$value"
      bad=1
    fi
  done

  [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/plasma-setup.desktop" ] ||
    { echo "MISSING desktop entry plasma-setup.desktop (shortcut)"; bad=1; }

  [ "$bad" -eq 0 ] && echo "all managed values match"
  return "$bad"
}

apply_table() {
  local file group sub key value current
  CHANGED=0
  while IFS='|' read -r file group sub key value; do
    case "${file:-}" in '' | '#'*) continue ;; esac
    current="$(kv_read "$file" "$group${sub:+/$sub}" "$key")"
    if [ "$current" != "$value" ]; then
      kv_write "$file" "$group${sub:+/$sub}" "$key" "$value"
      CHANGED=$((CHANGED + 1))
    fi
  done <<<"$TABLE"
  echo "config keys: $CHANGED changed"
}

apply_themes() {
  plasma-apply-lookandfeel -a "$LOOKANDFEEL" >/dev/null
  plasma-apply-desktoptheme "$PLASMA_STYLE" >/dev/null
  plasma-apply-colorscheme "$COLOR_SCHEME" >/dev/null
  plasma-apply-cursortheme "$CURSOR_THEME" --size "$CURSOR_SIZE" >/dev/null
  [ -x "$CHANGEICONS" ] && "$CHANGEICONS" "$ICON_THEME" >/dev/null
  if [ -f "$WALLPAPER" ]; then
    plasma-apply-wallpaperimage "$WALLPAPER" >/dev/null
  else
    echo "wallpaper: $WALLPAPER missing, skipped" >&2
  fi
  echo "themes: $LOOKANDFEEL / $PLASMA_STYLE / $COLOR_SCHEME / $ICON_THEME / $CURSOR_THEME"
}

apply_applets() {
  # task manager: clicking a grouped task opens the window previews
  js 'var t = panels()[0].widgets().filter(function (w) {
        return w.type === "org.kde.plasma.icontasks";
      })[0];
      if (!t) { print("task manager: not found"); } else {
        t.currentConfigGroup = ["General"];
        if (t.readConfig("groupedTaskVisualization", 0) != 1)
          t.writeConfig("groupedTaskVisualization", 1);
        print("task manager: groupedTaskVisualization=" +
              t.readConfig("groupedTaskVisualization", 0));
      }'

  # battery: a child applet of the system tray, unreachable from scripting
  local panel_id tray_id battery_id show_pct
  panel_id="$(js 'print(panels()[0].id)')"
  tray_id="$(awk '/^plugin=org\.kde\.plasma\.systemtray$/ { print prev }
    { if ($0 ~ /^\[Containments\]/) prev = $0 }' "$RC" | grep -oE '[0-9]+' | tail -1)"

  if [ -z "$panel_id" ] || [ -z "$tray_id" ]; then
    echo "battery: panel or system tray not found" >&2
    return 0
  fi

  battery_id="$(awk '/^plugin=org\.kde\.plasma\.battery$/ { print prev }
    { if ($0 ~ /^\[Containments\]/) prev = $0 }' "$RC" |
    grep -F "[Applets][$tray_id][Applets][" |
    sed -E 's/.*\[Applets\]\[([0-9]+)\]$/\1/')"

  [ -z "$battery_id" ] && { echo "battery: no battery applet in the tray" >&2; return 0; }

  show_pct="$(kreadconfig6 --file "$RC" --group Containments --group "$panel_id" \
    --group Applets --group "$tray_id" --group Applets --group "$battery_id" \
    --group Configuration --group General --key showPercentage)"
  if [ "$show_pct" != "true" ]; then
    kwriteconfig6 --file "$RC" --group Containments --group "$panel_id" \
      --group Applets --group "$tray_id" --group Applets --group "$battery_id" \
      --group Configuration --group General --key showPercentage true
    echo "battery: showPercentage set"
  else
    echo "battery: showPercentage already set"
  fi
}

apply_hotkeys() {
  local apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$apps"
  cat >"$apps/plasma-setup.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Plasma setup
NoDisplay=true
Actions=setup;

[Desktop Action setup]
Name=Re-apply the Plasma design
Exec=$HERE/setup.sh --force
EOF

  # commands for the desktop entry, plus KRunner on its usual key
  kv_write kglobalshortcutsrc plasma-setup.desktop setup \
    "Alt+Shift+Space,,Re-apply the Plasma design"
  kv_write kglobalshortcutsrc krunner _launch "Alt+Space,,Run Command"

  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
  systemctl --user restart plasma-kglobalaccel.service >/dev/null 2>&1 || true
  echo "hotkeys: Alt+Space = KRunner, Alt+Shift+Space = plasma/setup.sh --force"
}

MODE=apply
FORCE=0
case "${1:-}" in
  "") ;;
  --force) FORCE=1 ;;
  --check) MODE=check ;;
  --dump) MODE=dump ;;
  -h | --help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *)
    echo "usage: $(basename "$0") [--force|--check|--dump]" >&2
    exit 2
    ;;
esac

if [ "$MODE" = dump ]; then
  dump_table
  exit 0
fi

if [ "$MODE" = check ]; then
  check_table
  exit $?
fi

if [ "$FORCE" -eq 1 ]; then
  rm -f "$LOCK"
fi

if [ -e "$LOCK" ]; then
  echo "plasma setup already applied (rm $LOCK or use --force to apply again)"
  exit 0
fi

apply_table

if ! have_session; then
  echo "no Plasma session: config keys written, but themes/applets/hotkeys need one" >&2
  echo "run this again from inside the desktop session (no lock written)" >&2
  exit 1
fi

apply_themes
apply_applets
apply_hotkeys

if [ "$CHANGED" -gt 0 ]; then
  systemctl --user restart plasma-plasmashell
  echo "plasmashell restarted to pick up the new config"
fi

mkdir -p "$(dirname "$LOCK")"
: >"$LOCK"
echo "done (lock: $LOCK)"
