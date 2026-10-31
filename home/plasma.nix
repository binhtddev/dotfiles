# The Plasma desktop itself (themes, power, kwin, shortcuts, applets) is
# configured by plasma/setup.sh, not declaratively; this file only installs the
# theme packages, the wallpaper file and the GTK/Kvantum side of the theme.
{
  lib,
  pkgs,
  ...
}:
let
  # Dracutux is dark by default; switch to `.day` for the light variant.
  dracutuxVariants = (import ../pkgs/dracutux { }).variants;
  dracutux = dracutuxVariants.dark;

  dracutuxThemes = pkgs.callPackage ../pkgs/dracutux/arc-kde.nix { };
  dracutuxGtk = pkgs.callPackage ../pkgs/dracutux/arc-gtk.nix { };
  dracutuxIcons = pkgs.callPackage ../pkgs/dracutux/icons.nix { };
in
{
  home.packages = [
    dracutuxThemes
    dracutuxGtk
    dracutuxIcons
    # Dracutux only ships recoloured folder icons and inherits the rest of the
    # Papirus artwork (window-* marks included) from Papirus-Dark/Papirus, so
    # the parent themes have to be installed alongside the overlay.
    pkgs.papirus-icon-theme
    pkgs.kdePackages.qtstyleplugin-kvantum # engine for the Kvantum theme
    pkgs.libnotify # notify-send for vpn/rdp.sh notifications
    pkgs.freerdp # xfreerdp: RDP with auto-reconnect (krdc has no retry)
    pkgs.kdePackages.kdialog # password prompt for vpn/rdp.sh
  ];

  gtk = {
    # KDE's gtkconfig kded module can recreate ~/.config/gtk-2.0/gtkrc as a real
    # file, so allow home-manager to overwrite it instead of aborting.
    gtk2.force = true;

    # GTK apps, including the headerbar GTK4 draws itself, match the Dracutux
    # window decoration. The shared desktop/common.nix stays on adw-gtk3-dark
    # for the niri host.
    theme = lib.mkForce {
      name = dracutux.gtkTheme;
      package = dracutuxGtk;
    };

    # Dracutux is a thin overlay: only the coloured folder icons are ours, the
    # rest of the set is inherited from Papirus-Dark / Papirus. Plasma, GTK and
    # libadwaita all use it, so folders look the same everywhere.
    iconTheme = lib.mkForce {
      name = dracutux.gtkIconTheme;
      package = dracutuxIcons;
    };

    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = lib.mkForce (if dracutux.preferDark then 1 else 0);
      # GTK3 has no text-input-v3 support, so point it at the fcitx GTK3 module
      # directly (wayfrontend means GTK_IM_MODULE is not exported).
      "gtk-im-module" = "fcitx";
    };

    gtk4.extraConfig."gtk-application-prefer-dark-theme" = lib.mkForce dracutux.preferDark;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce (
    if dracutux.preferDark then "prefer-dark" else "default"
  );

  # Plugin paths for the Kvantum style.
  qt.enable = true;

  # The wallpaper is applied by plasma/setup.sh (plasma-apply-wallpaperimage);
  # keep a stable path for it outside the repo.
  home.file.".local/share/wallpapers/background.svg".source = ../assets/background.svg;

  xdg.configFile = {
    # Kvantum does not search XDG_DATA_DIRS for themes, only ~/.config/Kvantum,
    # ~/.themes and ~/.local/share/themes.
    "Kvantum/${dracutux.kvantum}".source = "${dracutuxThemes}/share/Kvantum/${dracutux.kvantum}";
  };
}
