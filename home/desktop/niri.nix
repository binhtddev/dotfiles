# Session-level styling niri does not provide itself (no desktop shell):
# cursor, an explicit GTK theme env var and Qt styling via Kvantum.
# Plasma hosts must NOT import this - they pick cursor and Qt style on their own.
{ pkgs, ... }:
{
  home = {
    sessionVariables = {
      GTK_THEME = "adw-gtk3-dark";
    };
    pointerCursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  qt = {
    enable = true;
    style.name = "kvantum";
  };
}
