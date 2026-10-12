# Desktop bits shared by every host: dark GTK theming for app-level consistency.
{ config, pkgs, ... }:
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
  };

  xdg.configFile = {
    "gtk-3.0/gtk.css".source = ./gtk.css;
    "gtk-4.0/gtk.css".source = ./gtk.css;
  };
}
