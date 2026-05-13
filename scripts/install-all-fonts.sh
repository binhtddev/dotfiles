#!/usr/bin/bash
set -euo pipefail

install_archive() {
  local url=$1 folder=$2
  local dir="$HOME/.local/share/fonts/$folder"
  [ -d "$dir" ] && return 0
  local tmp; tmp=$(mktemp -d)
  mkdir -p "$dir" "$tmp/out"
  curl -sL "$url" -o "$tmp/arc"
  case "$url" in
    *.zip) unzip -q "$tmp/arc" -d "$tmp/out" ;;
    *) tar -xf "$tmp/arc" -C "$tmp/out" ;;
  esac
  find "$tmp/out" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -n {} "$dir" \;
  fc-cache -f "$HOME/.local/share/fonts"
  rm -rf "$tmp"
}

install_archive "https://github.com/githubnext/monaspace/releases/download/v1.400/monaspace-variable-v1.400.zip" "Monaspace"
install_archive "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.tar.xz" "NerdFontsSymbolsOnly"
install_archive "https://github.com/binhtran432k/dotfiles/releases/download/archive/Window-Fonts.zip" "Window-Fonts"
