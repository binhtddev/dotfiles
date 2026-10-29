{ pkgs, ... }:
{
  # strongSwan daemon + swanctl client. The connection and private key live
  # outside the nix store so nothing secret ends up in the configuration;
  # vpn/setup.sh writes /etc/swanctl/tma.conf and the certificates.
  #
  # The daemon starting at boot does NOT dial anything: the child in
  # ../vpn/swanctl.conf has `start_action = none`, so a tunnel exists only
  # after an explicit `vpn.sh up` (badge / KRunner).
  services.strongswan-swanctl = {
    enable = true;
    includes = [ "/etc/swanctl/tma.conf" ];
  };

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
