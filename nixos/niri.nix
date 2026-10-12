{
  programs.niri.enable = true;
  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = { };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # niri has no Bluetooth UI; KDE gets bluedevil with Plasma instead.
  services.blueman.enable = true;
}
