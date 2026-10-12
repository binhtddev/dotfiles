{ lib, pkgs, ... }:
let
  # Plasma theme, colour scheme, aurorae decoration and Kvantum themes.
  arcKde = pkgs.callPackage ../pkgs/arc-kde.nix { };
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      # Arc Dark colours, Plasma style and Papirus icons. The window
      # decoration is Breeze (set below): the Arc aurorae titlebar is uglier
      # than KDE's default.
      theme = "Arc-Dark";
      colorScheme = "ArcDark"; # renamed from "Arc Dark" in pkgs/arc-kde.nix
      iconTheme = "Papirus-Dark";
      wallpaper = ../assets/swaybg.png;
    };

    configFile = {
      # Qt/KDE application style. Used to come from the Arc global theme.
      "kdeglobals"."KDE".widgetStyle = "kvantum";

      # KDE default window decoration.
      "kwinrc"."org.kde.kdecoration2" = {
        library = "org.kde.breeze";
        theme = "Breeze";
        BorderSize = "Normal";
      };

      # On Plasma Wayland fcitx5 must be started by KWin so that it can use
      # the text-input protocol.
      "kwinrc"."Wayland" = {
        InputMethod = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
        VirtualKeyboardEnabled = true;
      };

      # Natural scrolling for every touchpad (KWin per-class defaults, so no
      # vendor/product needed). Mice keep traditional scrolling.
      "kcminputrc"."Libinput/Defaults/Touchpad".NaturalScroll = true;

      # Kvantum theme; "theme" is lowercase because that is the key Kvantum
      # reads (QSettings keys are case-sensitive).
      "Kvantum/kvantum.kvconfig"."General".theme = "ArcDark";

      # KWin starts fcitx5, so mask the XDG autostart entry that would start a
      # second instance without the compositor socket.
      "autostart/org.fcitx.Fcitx5.desktop"."Desktop Entry" = {
        Type = "Application";
        Name = "Fcitx 5";
        Hidden = true;
      };

      # KDE's gtkconfig kded module rewrites ~/.config/gtk-2.0/gtkrc at login,
      # which collides with home-manager's declarative GTK config.
      "kded6rc"."Module-gtkconfig".autoload = false;
    };

    kwin = {
      edgeBarrier = 0;
      cornerBarrier = false;
      effects = {
        minimization.animation = "magiclamp";
        wobblyWindows.enable = true;
      };
      # Always on, independent of time or location.
      nightLight = {
        enable = true;
        mode = "constant";
        temperature.night = 4500;
      };
    };

    # Replaces swayidle: lock after 600s, monitors off after 600s,
    # suspend after 1200s.
    kscreenlocker = {
      lockOnResume = true;
      timeout = 10; # minutes
    };
    powerdevil = {
      AC = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 1200;
        };
        turnOffDisplay = {
          idleTimeout = 600;
          idleTimeoutWhenLocked = "immediately";
        };
      };
      battery = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 1200;
        };
        turnOffDisplay = {
          idleTimeout = 600;
          idleTimeoutWhenLocked = "immediately";
        };
      };
      lowBattery.whenLaptopLidClosed = "hibernate";
    };
  };

  home.packages = [
    arcKde
    pkgs.kdePackages.breeze-gtk # Breeze theme for GTK apps
    pkgs.kdePackages.qtstyleplugin-kvantum # engine for the Arc Kvantum theme
    pkgs.libnotify # notify-send for the eye-strain/stretch timers
  ];

  # KDE's gtkconfig kded module can recreate ~/.config/gtk-2.0/gtkrc as a real
  # file, so allow home-manager to overwrite it instead of aborting.
  gtk.gtk2.force = true;

  # GTK apps, including the headerbar GTK4 draws itself, match the Breeze
  # window decoration. The shared desktop/common.nix stays on adw-gtk3-dark
  # for the niri host.
  gtk.theme = lib.mkForce {
    name = "Breeze-Dark";
    package = pkgs.kdePackages.breeze-gtk;
  };

  # GTK3 has no text-input-v3 support, so point it at the fcitx GTK3 module
  # directly (waylandFrontend means GTK_IM_MODULE is not exported).
  gtk.gtk3.extraConfig."gtk-im-module" = "fcitx";

  # Plugin paths for the Kvantum style.
  qt.enable = true;

  xdg.configFile = {
    # Kvantum does not search XDG_DATA_DIRS for themes, only ~/.config/Kvantum,
    # ~/.themes and ~/.local/share/themes.
    "Kvantum/ArcDark".source = "${arcKde}/share/Kvantum/ArcDark";
  };
}
