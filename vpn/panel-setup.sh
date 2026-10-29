#!/usr/bin/env bash
#
# Panel setup for the TMA badge.
#
#   panel-setup.sh            add the badge (if absent) and place it before the
#                             system tray
#   panel-setup.sh show       same as above
#   panel-setup.sh hide       remove the badge from the panel
#
# The badge also hides itself while the VPN is down and no RDP session is
# running (applet setting "Hide when the VPN is down and no session is
# running"), so "hide" here is for getting rid of it entirely.
#
set -euo pipefail

CMD="${1:-show}"
RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

case "$CMD" in
  show | install | add) ;;
  hide | remove) ;;
  *)
    echo "usage: $(basename "$0") [show|hide]" >&2
    exit 2
    ;;
esac

js() {
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell \
    evaluateScript s "$1" 2>/dev/null | sed -n 's/^s "\(.*\)"$/\1/p'
}

if [ "$CMD" = "hide" ] || [ "$CMD" = "remove" ]; then
  js 'var p = panels()[0];
var n = 0;
p.widgets()
  .filter(function (w) { return w.type === "org.binhtd.tma"; })
  .forEach(function (w) { w.remove(); n++; });
print("removed " + n);'
  exit 0
fi

# 1. add the applet / drop the legacy badges
JS="$(mktemp --suffix=.js)"
trap 'rm -f "$JS"' EXIT
cat >"$JS" <<'EOF'
var WANTED = "org.binhtd.tma";
var LEGACY = "com.github.zren.commandoutput";
var panel = panels()[0];
if (!panel) {
  print("no panel found");
} else {
  panel.widgets()
    .filter(function (w) { return w.type === LEGACY; })
    .forEach(function (w) { w.remove(); });
  if (panel.widgets().filter(function (w) { return w.type === WANTED; }).length === 0)
    panel.addWidget(WANTED);
  print("ok");
}
EOF
js "$(cat "$JS")" >/dev/null

# 2. move it in front of the system tray
panel_id="$(js 'print(panels()[0].id)')"
tma_id="$(js 'var w=panels()[0].widgets().filter(function(x){return x.type==="org.binhtd.tma"})[0]; print(w?w.id:"")')"
tray_id="$(js 'var w=panels()[0].widgets().filter(function(x){return x.type==="org.kde.plasma.systemtray"})[0]; print(w?w.id:"")')"

if [ -n "$panel_id" ] && [ -n "$tma_id" ] && [ -n "$tray_id" ]; then
  order="$(kreadconfig6 --file "$RC" --group Containments --group "$panel_id" \
    --group General --key AppletOrder)"
  new="$(printf '%s' "$order" | tr ';' '\n' | grep -vx "$tma_id" |
    awk -v t="$tma_id" -v b="$tray_id" '$0 == b { print t } { print }' |
    paste -sd';' -)"
  if [ "$new" != "$order" ]; then
    kwriteconfig6 --file "$RC" --group Containments --group "$panel_id" \
      --group General --key AppletOrder "$new"
    systemctl --user restart plasma-plasmashell
  fi
fi
