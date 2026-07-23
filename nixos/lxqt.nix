{ pkgs, lib, ... }: {
  services = {
    xserver = {
      enable = true;
      desktopManager.lxqt.enable = true;
    };
    displayManager = {
      sddm.enable = true;
      sessionPackages = [ pkgs.lxqt.lxqt-wayland-session ];
    };
    graphical-desktop.enable = true;
  };

  environment.systemPackages = [ pkgs.labwc ];
  security = {
    polkit.enable = true;
    pam.services.swaylock = { };
  };
  programs = {
    dconf.enable = true;
    xwayland.enable = true;
  };
  xdg.portal = {
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.wlroots.default = lib.mkDefault [
      "wlr"
      "gtk"
    ];
  };
}
