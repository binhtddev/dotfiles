# Dracutux: Arc-derived KDE theme family.
#
# A port of Arc (PapirusDevelopmentTeam/arc-kde) recoloured with the helix
# "dracutux" palettes. Dark ("Dracutux") is the default, "Dracutux-Day" is the
# light variant.
#
# Installs, per variant:
#   share/color-schemes/<name>.colors
#   share/plasma/desktoptheme/<name>          (Arc-Color, colour-scheme driven)
#   share/aurorae/themes/<name>               (Arc titlebar, Breeze buttons)
#   share/Kvantum/<name>
#   share/plasma/look-and-feel/<id>           (defaults + splash wallpaper)
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  helpers = import ./lib.nix { inherit lib; };
  inherit (helpers) rgb;

  palette = import ./palette.nix;
  mkColorscheme = import ./colorscheme.nix { inherit rgb; };
  mkAurorae = import ./aurorae.nix { inherit rgb; };

  # Shared wallpaper: the look-and-feel splash and the [Wallpaper] default of
  # the global theme. builtins.path keeps the store path stable across commits
  # (so neither the splash nor the theme re-applies with a new path).
  wallpaper = builtins.path {
    path = ../../assets/background.svg;
    name = "background.svg";
  };

  # Two-pass recolouring: sources are first replaced by unique tokens, then the
  # tokens by their target colour. This avoids chains such as
  # #f5f6f7 -> #ffffff -> #eeeeff.
  token = to: "__DRACUTUX_${lib.removePrefix "#" to}__";

  recolorWith =
    wrap: mapping:
    let
      pairs = lib.mapAttrsToList (from: to: { inherit from to; }) mapping;
      targets = lib.unique (map (p: p.to) pairs);
    in
    lib.concatStringsSep "\n" (
      map (p: wrap "s|${p.from}|${token p.to}|g") pairs ++ map (to: wrap "s|${token to}|${to}|g") targets
    );

  recolorFile = file: mapping: recolorWith (expr: "sed -i '${expr}' ${file}") mapping;

  recolorTree =
    dir: mapping:
    recolorWith (expr: "find ${dir} -type f -name '*.svg' -exec sed -i '${expr}' {} +") mapping;

  variants = {
    dark = {
      name = "Dracutux";
      id = "com.github.binhtd.dracutux";
      palette = palette.dark;
      plasmaBase = "Arc-Color";
      auroraeBase = "Arc-Dark";
      kvantumBase = "ArcDark";
      # Dracutux is a thin overlay over Papirus: the coloured folder icons are
      # ours, the rest of the set (and the window-* marks KWin does not use)
      # falls back through Inherits=Papirus-Dark. KWin draws its own window
      # buttons, so the GTK-side icon overlay works here too.
      iconTheme = "Dracutux";
      auroraeMap = {
        "#2f343f" = palette.dark.window;
        "#272a33" = palette.dark.window_alt;
        "#15171c" = palette.dark.shadow;
        "#b9bcc2" = palette.dark.text;
        "#c4c7cc" = palette.dark.subtle_text;
        "#5f697f" = palette.dark.inactive_fg;
        "#5294e2" = palette.dark.purple;
        "#ffffff" = palette.dark.text;
        "#d7787d" = palette.dark.red;
        "#cc575d" = palette.dark.red;
        "#be3841" = palette.dark.red_dark;
      };
      kvantumMap = {
        "#2f343f" = palette.dark.window;
        "#353945" = palette.dark.window_alt;
        "#272a33" = palette.dark.window_alt;
        "#262934" = palette.dark.window_alt;
        "#2e3340" = palette.dark.window_alt;
        "#383c4a" = palette.dark.view;
        "#414857" = palette.dark.button;
        "#444a58" = palette.dark.button_alt;
        "#4b5165" = palette.dark.border;
        "#505666" = palette.dark.border;
        "#101828" = palette.dark.shadow;
        "#d3dae3" = palette.dark.text;
        "#ffffff" = palette.dark.text;
        "#8f9eb7" = palette.dark.subtle_text;
        "#8f939d" = palette.dark.inactive_fg;
        "#767b87" = palette.dark.inactive_fg;
        "#5294e2" = palette.dark.purple;
        "#4877b1" = palette.dark.purple_dark;
        "#3daee9" = palette.dark.cyan;
        "#4caf50" = palette.dark.green;
        "#4e9a06" = palette.dark.green;
        "#53f23b" = palette.dark.green;
        "#f44336" = palette.dark.red;
        "#ff2a2a" = palette.dark.red;
        "#ff0000" = palette.dark.red;
        "#ff9800" = palette.dark.orange;
        "#f09d00" = palette.dark.yellow;
        "#ff00ff" = palette.dark.pink;
        "#4285f4" = palette.dark.blue;
      };
    };

    day = {
      name = "Dracutux-Day";
      id = "com.github.binhtd.dracutux-day";
      palette = palette.day;
      plasmaBase = "Arc-Color";
      auroraeBase = "Arc";
      kvantumBase = "Arc";
      iconTheme = "Dracutux-Day";
      auroraeMap = {
        "#e7e8eb" = palette.day.window;
        "#7a7f8b" = palette.day.text;
        "#525d76" = palette.day.inactive_fg;
        "#5294e2" = palette.day.purple;
        "#ffffff" = palette.day.window_alt;
        "#f68086" = palette.day.red;
        "#f46067" = palette.day.red;
        "#f13039" = palette.day.red_dark;
      };
      kvantumMap = {
        "#5c616c" = palette.day.text;
        "#f9f9fa" = palette.day.view;
        "#f5f6f7" = palette.day.window;
        "#e7e8eb" = palette.day.window_alt;
        "#d4d5db" = palette.day.border;
        "#d3d4d8" = palette.day.border;
        "#cfd6e6" = palette.day.border;
        "#b8babf" = palette.day.inactive_fg;
        "#bebebe" = palette.day.border;
        "#444a58" = palette.day.window_alt;
        "#272c35" = palette.day.shadow;
        "#3b3c3e" = palette.day.text;
        "#3daee9" = palette.day.cyan;
        "#ff4d4d" = palette.day.red;
        "#b74aff" = palette.day.pink;
        "#101828" = palette.day.shadow;
        "#5294e2" = palette.day.purple;
      };
    };
  };

  defaults =
    v:
    let
      p = v.palette;
    in
    ''
      [kdeglobals][KDE]
      widgetStyle=kvantum

      [kdeglobals][General]
      ColorScheme=${p.name}

      [kdeglobals][Icons]
      Theme=${v.iconTheme}

      [plasmarc][Theme]
      name=${p.name}

      # The global theme owns the desktop background, like KDE's Breeze does
      # with Image=Next (Arc left this out, which is why another wallpaper
      # could show up after applying it).
      [Wallpaper]
      Image=file://${wallpaper}

      [kwinrc][org.kde.kdecoration2]
      library=org.kde.kwin.aurorae
      theme=__aurorae__svg__${p.name}
      BorderSize=Normal
      ButtonsOnLeft=
      ButtonsOnRight=IAX

      [kcminputrc][Mouse]
      cursorTheme=breeze_cursors
    '';

  metadata =
    v:
    let
      p = v.palette;
    in
    builtins.toJSON {
      KPackageStructure = "Plasma/LookAndFeel";
      KPlugin = {
        Authors = [ { Name = "Binh Tran"; } ];
        Category = "";
        Description = "Arc-based ${p.name} theme with the dracutux palette";
        Id = v.id;
        License = "GPL-3.0-or-later";
        Name = p.name;
        Website = "https://github.com/binhtddev/dotfiles";
      };
    };

  # Plasma 6's KCM only lists packages with metadata.json; the legacy
  # metadata.desktop that arc-kde ships makes the Plasma Style page look empty
  # (the CLI tools still list those, which is why the style appears applied).
  plasmaMetadata =
    v:
    let
      p = v.palette;
    in
    builtins.toJSON {
      KPlugin = {
        Authors = [
          {
            Name = "Alexey Varfolomeev";
            Email = "varlesh@gmail.com";
          }
        ];
        Category = "";
        Description = "Arc-based ${p.name} Plasma style with the dracutux palette";
        EnabledByDefault = true;
        Id = p.name;
        License = "CC-BY-SA";
        Name = p.name;
        Version = "1.0";
        Website = "https://github.com/binhtddev/dotfiles";
      };
      "X-Plasma-API" = "5.0";
    };

  installVariant =
    v:
    let
      p = v.palette;
      aur = mkAurorae p;
    in
    ''
      # --- colour scheme ---------------------------------------------------
      install -Dm644 ${builtins.toFile "${p.name}.colors" (mkColorscheme p)} "$out/share/color-schemes/${p.name}.colors"

      # --- Plasma style (Arc-Color follows the colour scheme) ---------------
      cp -r "$out/share/plasma/desktoptheme/${v.plasmaBase}" \
        "$out/share/plasma/desktoptheme/${p.name}"
      rm -f "$out/share/plasma/desktoptheme/${p.name}/metadata.desktop"
      install -m644 ${builtins.toFile "${p.name}-plasma.json" (plasmaMetadata v)} "$out/share/plasma/desktoptheme/${p.name}/metadata.json"

      # --- Aurorae window decoration ---------------------------------------
      cp -r "$out/share/aurorae/themes/${v.auroraeBase}" \
        "$out/share/aurorae/themes/${p.name}"
      rm -f "$out/share/aurorae/themes/${p.name}/${v.auroraeBase}rc"
      install -m644 ${builtins.toFile "${p.name}rc" aur.rc} \
        "$out/share/aurorae/themes/${p.name}/${p.name}rc"
      ${recolorTree "$out/share/aurorae/themes/${p.name}" v.auroraeMap}
      install -m644 ${builtins.toFile "${p.name}-close.svg" aur.close} \
        "$out/share/aurorae/themes/${p.name}/close.svg"
      install -m644 ${builtins.toFile "${p.name}-maximize.svg" aur.maximize} \
        "$out/share/aurorae/themes/${p.name}/maximize.svg"
      install -m644 ${builtins.toFile "${p.name}-minimize.svg" aur.minimize} \
        "$out/share/aurorae/themes/${p.name}/minimize.svg"
      install -m644 ${builtins.toFile "${p.name}-restore.svg" aur.restore} \
        "$out/share/aurorae/themes/${p.name}/restore.svg"
      sed -i \
        -e 's|^Name=.*|Name=${p.name}|' \
        -e 's|^X-KDE-PluginInfo-Name=.*|X-KDE-PluginInfo-Name=${p.name}|' \
        "$out/share/aurorae/themes/${p.name}/metadata.desktop"

      # --- Kvantum ---------------------------------------------------------
      cp -r "$out/share/Kvantum/${v.kvantumBase}" "$out/share/Kvantum/${p.name}"
      mv "$out/share/Kvantum/${p.name}/${v.kvantumBase}.kvconfig" \
        "$out/share/Kvantum/${p.name}/${p.name}.kvconfig"
      mv "$out/share/Kvantum/${p.name}/${v.kvantumBase}.svg" \
        "$out/share/Kvantum/${p.name}/${p.name}.svg"
      ${recolorFile ''"$out/share/Kvantum/${p.name}/${p.name}.svg"'' v.kvantumMap}

      # --- Global theme (look-and-feel) ------------------------------------
      lf="$out/share/plasma/look-and-feel/${v.id}"
      install -d "$lf/contents/splash/images"
      install -m644 ${builtins.toFile "${v.id}.json" (metadata v)} "$lf/metadata.json"
      install -m644 ${builtins.toFile "${v.id}-defaults" (defaults v)} "$lf/contents/defaults"
      install -m644 ${./splash/Splash.qml} "$lf/contents/splash/Splash.qml"
      install -m644 ${wallpaper} "$lf/contents/splash/images/background.svg"
    '';
in
stdenvNoCC.mkDerivation {
  pname = "dracutux-themes";
  version = "unstable-2025-12-17";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "arc-kde";
    rev = "b67cdb76ccbe33bdb47e82ecbdd0eed3c0cea29e";
    hash = "sha256-WNlC2tjiuMMT4EJn2O5BPP9EUJgv/ce2hA8EWlJPC9Q=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    make install PREFIX= DESTDIR="$out"

    # Upstream ships Arc/ArcDark; the Dracutux variants replace them.
    rm -f "$out"/share/color-schemes/*.colors

    ${installVariant variants.dark}
    ${installVariant variants.day}

    # Upstream's Arc/Arc-Color styles are legacy metadata.desktop packages, so
    # Plasma 6 does not list them; drop them instead of shipping dead entries.
    rm -rf "$out/share/plasma/desktoptheme/Arc-Color" "$out/share/plasma/desktoptheme/Arc-Dark"

    runHook postInstall
  '';

  meta = {
    description = "Dracutux (dark) and Dracutux-Day (light) themes for KDE Plasma";
    homepage = "https://github.com/binhtddev/dotfiles";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
