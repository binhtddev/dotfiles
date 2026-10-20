{ lib, pkgs, ... }:
{
  boot = {
    plymouth.enable = true;
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    # secret service for GTK/libsecret apps (Brave, Thunderbird, ...)
    gnome.gnome-keyring.enable = true;
  };
  environment = {
    # Electron/Chromium apps on Wayland
    sessionVariables.NIXOS_OZONE_WL = "1";
    plasma6.excludePackages = with pkgs; [
      kdePackages.elisa # Simple music player aiming to provide a nice experience for its users
      kdePackages.kdepim-runtime # Akonadi agents and resources
      kdePackages.kmahjongg # KMahjongg is a tile matching game for one or two players
      kdePackages.kmines # KMines is the classic Minesweeper game
      kdePackages.konversation # User-friendly and fully-featured IRC client
      kdePackages.kpat # KPatience offers a selection of solitaire card games
      kdePackages.ksudoku # KSudoku is a logic-based symbol placement puzzle
      kdePackages.ktorrent # Powerful BitTorrent client
    ];
    systemPackages = with pkgs; [
      adwaita-icon-theme # for lacking icon in gtk apps
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    ];
  };

  # NixOS's nixos-rebuild-sycoca unit wipes ~/.cache/ksycoca* at every session
  # start, but it is only needed when the system generation changed. The
  # unconditional wipe forces KDE to rebuild the service cache at login, which
  # shows up as a panel/task manager that appears late. Make it conditional.
  systemd.user.services.nixos-rebuild-sycoca.script = lib.mkForce ''
    cache="''${XDG_CACHE_HOME:-$HOME/.cache}"
    stamp="$cache/nixos-sycoca.stamp"
    current="$(readlink -f /run/current-system)"
    if [ "$(cat "$stamp" 2>/dev/null)" != "$current" ]; then
      rm -fv "$cache"/ksycoca*
      echo "$current" > "$stamp"
    fi
  '';
}
