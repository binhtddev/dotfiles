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

  # SVG wallpaper: the viewBox lets Qt render it at the screen size. The
  # content-addressed store path keeps the generated script byte-identical
  # across commits, so it is not re-applied (and does not visibly switch)
  # at every login.
  wallpaper = builtins.path {
    path = ../assets/background.svg;
    name = "background.svg";
  };
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      inherit (dracutux)
        lookAndFeel
        colorScheme
        iconTheme
        ;

      theme = dracutux.plasmaStyle;

      # "inspired from Breeze": Breeze cursors, Dracutux everything else.
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };

      inherit wallpaper;
    };

    configFile = {
      # Qt/KDE application style. The Kvantum theme itself is set below.
      "kdeglobals"."KDE".widgetStyle = "kvantum";

      # Dracutux window decoration: Arc titlebar, Breeze-style buttons.
      # Aurorae v2 ignores the theme rc's LeftButtons/RightButtons, so the
      # button layout has to come from kwinrc (KWin's own default made the
      # close button disappear).
      "kwinrc"."org.kde.kdecoration2" = {
        library = "org.kde.kwin.aurorae";
        theme = "__aurorae__svg__${dracutux.aurorae}";
        BorderSize = "Normal";
        ButtonsOnLeft = "";
        ButtonsOnRight = "IAX";
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
      "Kvantum/kvantum.kvconfig"."General".theme = dracutux.kvantum;

      # KWin starts fcitx5, so mask the XDG autostart entry that would start a
      # second instance without the compositor socket.
      "autostart/org.fcitx.Fcitx5.desktop"."Desktop Entry" = {
        Type = "Application";
        Name = "Fcitx 5";
        Hidden = true;
      };

      # KDE's gtkconfig kded module rewrites ~/.config/gtk-2.0/gtkrc at login,
      # which collides with home-manager's declarative GTK config. The other
      # three modules ship empty/broken in this packaging and only log
      # "The kded module name ... is invalid!" at startup.
      "kded6rc" = {
        "Module-gtkconfig".autoload = false;
        "Module-oom-notifier".autoload = false;
        "Module-plasma-session-shortcuts".autoload = false;
        "Module-wpad-detector".autoload = false;
      };
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
      # KDE's LowBattery profile defaults AutoSuspendIdleTimeoutSec to 30 while
      # the display-off timer stays at 600, so the machine would sleep with the
      # screen still on. Keep it aligned with the AC/Battery profiles instead.
      lowBattery = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 1200;
        };
        whenLaptopLidClosed = "hibernate";
      };
    };
  };

  home.packages = [
    dracutuxThemes
    dracutuxGtk
    dracutuxIcons
    # Dracutux only ships recoloured folder icons and inherits the rest of the
    # Papirus artwork (window-* marks included) from Papirus-Dark/Papirus, so
    # the parent themes have to be installed alongside the overlay.
    pkgs.papirus-icon-theme
    pkgs.kdePackages.qtstyleplugin-kvantum # engine for the Kvantum theme
    pkgs.libnotify # notify-send for the eye-strain/stretch timers
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

  xdg.configFile = {
    # Kvantum does not search XDG_DATA_DIRS for themes, only ~/.config/Kvantum,
    # ~/.themes and ~/.local/share/themes.
    "Kvantum/${dracutux.kvantum}".source = "${dracutuxThemes}/share/Kvantum/${dracutux.kvantum}";
  };
}
