# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  win32yank = pkgs.callPackage ./win32yank.nix { };
  bifont = pkgs.callPackage ./bifont.nix { };
  dracutux-themes = pkgs.callPackage ./dracutux/arc-kde.nix { };
  dracutux-gtk = pkgs.callPackage ./dracutux/arc-gtk.nix { };
  dracutux-icons = pkgs.callPackage ./dracutux/icons.nix { };
}
