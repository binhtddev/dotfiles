#!/usr/bin/env bash
# Regenerate the vendored Dracutux folder icons.
#
#   pkgs/dracutux/icons/update-icons.sh /nix/store/…-papirus-icon-theme-<version>
#
# Papirus ships its folder artwork on a violet ramp. We shift that ramp onto
# the Dracutux palette once, here, and commit the result, so the Nix build is a
# plain `cp -r` instead of a symlinkJoin over ~100k Papirus files (which took
# minutes) — and so the icons do not depend on rebuilding Papirus at all.
#
# Re-run this after bumping papirus-icon-theme, with the new store path as the
# argument. Only places/ folder art is vendored; everything else is inherited
# from the parent theme through index.theme's Inherits chain.
#
# Layout mirrors Papirus: every size directory that has a places/ in the parent
# theme, plus the @2x directories as links to their 1x sibling (Papirus ships
# them that way too). Entries Papirus ships as symlinks stay relative symlinks
# instead of becoming duplicated copies.
set -euo pipefail

papirus="${1:?usage: update-icons.sh /nix/store/…-papirus-icon-theme-*}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# name | parent theme | folder main | folder dark | folder shadow
variants=(
  "Dracutux|Papirus-Dark|#8f6fd6|#443377|#221a33"   # purple_dark / selection
  "Dracutux-Day|Papirus|#7744bb|#5c3399|#3a2a5e"    # day purple / day purple_dark
)

for entry in "${variants[@]}"; do
  IFS='|' read -r name parent main dark shadow <<<"$entry"
  src="$papirus/share/icons/$parent"
  dest="$here/$name"

  echo "==> $name (from $parent)"
  rm -rf "$dest"
  install -d "$dest"

  # Papirus's index.theme, identity changed, Inherits/Directories kept intact.
  sed -e "s|^Name=.*|Name=$name|" \
      -e "s|^Comment=.*|Comment=Dracutux: $parent with Dracutux-coloured folders|" \
      -e "s|^Inherits=.*|Inherits=$parent,hicolor|" \
      "$src/index.theme" >"$dest/index.theme"

  for size_dir in "$src"/*/places; do
    [ -d "$size_dir" ] || continue
    size="$(basename "$(dirname "$size_dir")")"
    case "$size" in *@2x) continue ;; esac

    places="$dest/$size/places"
    install -d "$places"

    for file in "$size_dir"/*violet*.svg; do
      [ -e "$file" ] || continue
      target="${file##*/}"
      target="${target//-violet/}"

      if [ -L "$file" ]; then
        link="$(readlink "$file")"
        ln -sf "${link//-violet/}" "$places/$target"
      else
        install -m644 "$file" "$places/$target"
        sed -i -e "s|#7e57c2|$main|g" \
               -e "s|#5d399b|$dark|g" \
               -e "s|#2c1e44|$shadow|g" "$places/$target"
        [ "$target" = "folder.svg" ] && cp -p "$places/$target" "$places/inode-directory.svg"
      fi
    done
  done

  # 22x22@2x etc. are links to the 1x directory in Papirus; mirror that, but
  # only for sizes we actually vendored (18x18 has no folder art, and a link to
  # a directory we do not ship would be a dangling symlink in the store).
  for link in "$src"/*@2x; do
    [ -L "$link" ] || continue
    base="${link##*/}"
    [ -d "$dest/${base%@2x}" ] || continue
    ln -sfn "${base%@2x}" "$dest/$base"
  done

  printf '    %s files, %s\n' \
    "$(find "$dest" -type f | wc -l)" \
    "$(du -sh "$dest" | cut -f1)"
done
