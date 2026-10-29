# Dracutux icon themes: Papirus with Dracutux-coloured folders.
#
# The recoloured folder icons are vendored in ./icons, so this build is a plain
# copy: no papirus-icon-theme rebuild and no symlinkJoin over the whole ~100k
# file Papirus tree (which took minutes on every build).
#
# Regenerate the vendored tree after bumping papirus-icon-theme:
#
#   pkgs/dracutux/icons/update-icons.sh /nix/store/…-papirus-icon-theme-<version>
#
# Only places/ folder art lives here: the coloured folder icons (Papirus's own
# violet ramp shifted onto the Dracutux palette) plus inode-directory. Everything
# else — apps, actions, devices, the monochrome/white details of an icon, and the
# window-* marks GTK apps resolve from the icon theme — is deliberately left
# alone and falls back to Papirus through index.theme's Inherits chain.
#
# Regenerate the vendored tree after bumping papirus-icon-theme:
#
#   pkgs/dracutux/icons/update-icons.sh /nix/store/…-papirus-icon-theme-<version>
{
  lib,
  stdenvNoCC,
  papirus-icon-theme,
}:
stdenvNoCC.mkDerivation {
  pname = "dracutux-icons";
  version = "1.0";

  src = ./icons;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    # Papirus-Dark / Papirus are the parent themes. Referencing them here keeps
    # papirus-icon-theme as a declared dependency of this theme, so the fallback
    # cannot silently disappear; install it alongside (home/plasma.nix does).
    for parent in Papirus-Dark Papirus; do
      if [ ! -d "${papirus-icon-theme}/share/icons/$parent" ]; then
        echo "dracutux-icons: parent theme $parent is missing from papirus-icon-theme" >&2
        exit 1
      fi
    done

    install -d "$out/share/icons"
    cp -r --no-preserve=ownership \
      "$src/Dracutux" \
      "$src/Dracutux-Day" \
      "$out/share/icons/"
    runHook postInstall
  '';

  passthru.inherits = [
    "Papirus-Dark"
    "Papirus"
  ];

  meta = {
    description = "Papirus icon themes with Dracutux-coloured folders";
    homepage = "https://github.com/binhtddev/dotfiles";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
