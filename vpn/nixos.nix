{ lib, pkgs, ... }:
{
  # strongSwan: the connection and private key live outside the nix store so
  # nothing secret ends up in the configuration; vpn/setup.sh writes
  # /etc/swanctl/tma.conf and the certificates.
  #
  # Nothing is dialled implicitly: the child in ../vpn/swanctl.conf has
  # `start_action = none`, so a tunnel only exists after an explicit
  # `vpn.sh up` (badge / KRunner).
  services.strongswan-swanctl = {
    enable = true;
    includes = [ "/etc/swanctl/tma.conf" ];
  };

  # Keep charon off the boot path as well: without `wantedBy` the daemon is not
  # started at login, vpn-root.sh starts it on the first connect. This also
  # removes the only consumer of network-online.target, so boot no longer waits
  # ~6 s for NetworkManager-wait-online.
  systemd.services.strongswan-swanctl.wantedBy = lib.mkForce [ ];

  # NixOS only puts strongswan on the daemon's own PATH, and swanctl lives in
  # sbin, so expose it (and openssl, used by setup.sh) to the system profile.
  environment.systemPackages = with pkgs; [
    strongswan
    openssl
  ];

  # Make sure the included file exists from first boot: the unit runs
  # `swanctl --load-all` on start, which would fail on a missing include
  # before vpn/setup.sh has ever run. `f` only creates it when absent.
  systemd.tmpfiles.rules = [ "f /etc/swanctl/tma.conf 0600 root root -" ];

  # Let wheel start/stop the VPN from the panel badge or KRunner without a
  # polkit prompt. Scoped to this exact program.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.policykit.exec"
          && action.lookup("program") == "/home/binhtd/dotfiles/vpn/vpn.sh"
          && subject.isInGroup("wheel"))
        return polkit.Result.YES;
    });
  '';
}
