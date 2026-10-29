# Dracutux GTK themes: arc-theme (jnsh/arc-theme) with the dracutux palettes
# and Breeze-style headerbar buttons.
#
# The renamed variants are:
#   Arc-Dark -> Dracutux
#   Arc      -> Dracutux-Day
{
  lib,
  arc-theme,
  glib,
}:
let
  palette = import ./palette.nix;
  mkButtons = import ./gtk/buttons.nix;

  # Exact strings from arc-theme's common/*/sass/_colors.scss. The file is
  # identical for gtk-3.0 and gtk-4.0, and the SCSS picks per variant, so a
  # single mapping covers both variants and both GTK versions.
  scssMap = {
    "$base_color: if($variant !='dark', #ffffff, #404552);" =
      "$base_color: if($variant !='dark', #eeeeff, #222233);";
    "$text_color: if($variant !='dark', #5c616c, #D3DAE3);" =
      "$text_color: if($variant !='dark', #444433, #ffffee);";
    "$bg_color: if($variant !='dark', #F5F6F7, #383C4A);" =
      "$bg_color: if($variant !='dark', #ffffff, #111122);";
    "$fg_color: if($variant !='dark', #5c616c, #D3DAE3);" =
      "$fg_color: if($variant !='dark', #444433, #ffffee);";
    "$selected_fg_color: #ffffff;" = "$selected_fg_color: if($variant !='dark', #ffffff, #222233);";
    "$selected_bg_color: #5294e2;" = "$selected_bg_color: if($variant !='dark', #7744bb, #bb99ff);";
    "#e7e8eb" = "#ffffff";
    "$header_bg: transparentize(#2f343f, 0.03);" = "$header_bg: transparentize(#111122, 0.03);";
    "$header_bg: #2f343f;" = "$header_bg: #111122;";
    "#353945" = "#1a1a2c";
    "#BAC3CF" = "#ffffee";
    "$warning_color: #F27835;" = "$warning_color: #aa6633;";
    "$error_color: #FC4138;" = "$error_color: #c22c2c;";
    "$success_color: #73d216;" = "$success_color: #33aa55;";
    "$destructive_color: #F04A50;" = "$destructive_color: #c22c2c;";
    "$suggested_color: #4DADD4;" = "$suggested_color: #4477cc;";
    "$drop_target_color: #F08437;" = "$drop_target_color: #aa6633;";
    "#cfd6e6" = "#d8d8e8";
  };

  variants = {
    dark = {
      theme = "Dracutux";
      base = "Arc-Dark";
      palette = palette.dark;
      iconTheme = "Dracutux";
    };
    day = {
      theme = "Dracutux-Day";
      base = "Arc";
      palette = palette.day;
      iconTheme = "Dracutux-Day";
    };
  };

  installVariant =
    v:
    let
      buttons = mkButtons v.palette;
      cssFile = builtins.toFile "${v.theme}.css" buttons.css;
      buttonFiles = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: content:
          ''install -m644 ${builtins.toFile "${v.theme}-${name}" content} "$out/share/themes/${v.theme}/assets-dracutux/${name}"''
        ) buttons.files
      );
    in
    ''
      mv "$out/share/themes/${v.base}" "$out/share/themes/${v.theme}"
      theme="$out/share/themes/${v.theme}"

      sed -i \
        -e 's|^Name=.*|Name=${v.theme}|' \
        -e 's|^GtkTheme=.*|GtkTheme=${v.theme}|' \
        -e 's|^MetacityTheme=.*|MetacityTheme=${v.theme}|' \
        -e 's|^IconTheme=.*|IconTheme=${v.iconTheme}|' \
        -e 's|^CursorTheme=.*|CursorTheme=breeze_cursors|' \
        -e 's|^ButtonLayout=.*|ButtonLayout=:minimize,maximize,close|' \
        "$theme/index.theme"

      # Breeze-style titlebar buttons.
      install -d "$theme/assets-dracutux"
      ${buttonFiles}

      # Arc ships one-line gtk.css stubs that @import the real CSS out of
      # gtk.gresource. That breaks whenever GTK does not register the resource
      # ("Failed to import: The resource at /org/gnome/arc-theme/… does not
      # exist", see jnsh/arc-theme#234), and the CSS parser aborts the whole
      # sheet. Unpack the resources into real files instead and append our
      # overrides to the resulting CSS.
      for gtkdir in gtk-3.0 gtk-4.0; do
        dir="$theme/$gtkdir"
        resource="$dir/gtk.gresource"
        [ -f "$resource" ] || continue

        ${glib.dev}/bin/gresource list "$resource" | while read -r path; do
          case "$path" in
            */assets/*)
              rel="''${path#*/assets/}"
              mkdir -p "$dir/assets/$(dirname "$rel")"
              ${glib.dev}/bin/gresource extract "$resource" "$path" > "$dir/assets/$rel"
              ;;
          esac
        done

        for cssfile in gtk.css gtk-dark.css; do
          file="$dir/$cssfile"
          [ -f "$file" ] || continue
          imported="$(sed -n 's|.*resource://\([^"]*\)".*|\1|p' "$file" | head -1)"
          if [ -n "$imported" ]; then
            ${glib.dev}/bin/gresource extract "$resource" "$imported" > "$file.new"
            cat ${cssFile} >> "$file.new"
            mv "$file.new" "$file"
          else
            cat ${cssFile} >> "$file"
          fi
        done

        rm -f "$resource"
      done
    '';
in
arc-theme.overrideAttrs (old: {
  pname = "dracutux-gtk";

  postPatch = (old.postPatch or "") + ''
    for f in common/gtk-3.0/sass/_colors.scss common/gtk-4.0/sass/_colors.scss; do
      python3 ${./gtk/patch-colors.py} "$f" ${lib.escapeShellArg (builtins.toJSON scssMap)}
    done
  '';

  # Only GTK3/GTK4, and only the two variants we rename below.
  mesonFlags = old.mesonFlags ++ [
    "-Dthemes=gtk3,gtk4"
    "-Dvariants=light,dark"
  ];

  postInstall = ''
    rm -rf "$out/share/themes/Arc-Darker" "$out/share/themes/Arc-Lighter"

    ${installVariant variants.dark}
    ${installVariant variants.day}
  '';

  meta = old.meta // {
    description = "Dracutux and Dracutux-Day GTK themes (Arc-based)";
    homepage = "https://github.com/binhtddev/dotfiles";
  };
})
