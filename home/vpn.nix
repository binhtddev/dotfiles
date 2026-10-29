# Launch the TMA IPsec VPN from the desktop launcher.
#
# These entries show up in KRunner / Kickoff / Dolphin (KDE) and in fuzzel or
# any XDG launcher, so they keep working if the session is not Plasma.
# The scripts elevate through pkexec, which pops the polkit prompt in the
# running session; nothing here needs a terminal.
{ config, pkgs, ... }:
let
  script = "${config.home.homeDirectory}/dotfiles/vpn/vpn.sh";
  rdpScript = "${config.home.homeDirectory}/dotfiles/vpn/rdp.sh";
  # Papirus ships no FreeRDP icon (only gnome-rdp / remmina / krdc); this is
  # KDE's canonical "remote desktop" name and Dracutux inherits Papirus-Dark.
  rdpIcon = "preferences-desktop-remote-desktop";
  # The store binary is NOT setuid; NixOS provides the setuid wrapper here.
  pkexec = "/run/wrappers/bin/pkexec";
  # pkexec runs the program in a minimal environment — its PATH contains no Nix
  # store paths, so `#!/usr/bin/env bash` cannot resolve bash. Invoke the
  # interpreter explicitly; vpn.sh then fixes up PATH for swanctl itself.
  bash = "${pkgs.bash}/bin/bash";

  entry =
    {
      name,
      action,
      comment,
    }:
    {
      inherit name comment;
      exec = "${pkexec} ${bash} ${script} ${action}";
      icon = "network-vpn";
      terminal = false;
      type = "Application";
      categories = [ "Network" ];
      settings = {
        Keywords = "vpn;tma;ipsec;strongswan;tunnel;";
        StartupNotify = "false";
      };
    };
in
{
  xdg.desktopEntries = {
    tma-vpn-connect = entry {
      name = "TMA VPN — Connect";
      action = "up";
      comment = "Bring the TMA IPsec tunnel up";
    };
    tma-vpn-disconnect = entry {
      name = "TMA VPN — Disconnect";
      action = "down";
      comment = "Tear the TMA IPsec tunnel down";
    };
    tma-vpn-toggle = entry {
      name = "TMA VPN — Toggle";
      action = "toggle";
      comment = "Connect the TMA IPsec tunnel, or disconnect it if already up";
    };

    # FreeRDP installs no .desktop file of its own, so KDE cannot match its
    # window (WM_CLASS "xfreerdp") to an application and falls back to a
    # generic icon in the task manager. This entry supplies the association,
    # the Papirus icon, and a launcher in KRunner/Kickoff.
    tma-rdp = {
      name = "Office desktop (TMA RDP)";
      comment = "Open the office Windows desktop, bringing the VPN up if needed";
      exec = "${bash} ${rdpScript}";
      icon = rdpIcon;
      terminal = false;
      type = "Application";
      categories = [
        "Network"
        "RemoteAccess"
      ];
      settings = {
        StartupWMClass = "xfreerdp";
        Keywords = "rdp;freerdp;windows;office;desktop;remote;tma;";
        StartupNotify = "false";
      };
    };
  };

  # Panel badge: status + left click toggles, right click = Plasma's applet
  # menu with VPN/RDP actions. Installed by vpn/panel-setup.sh.
  home.file.".local/share/plasma/plasmoids/org.binhtd.tma".source = ./plasma-tma;
}
