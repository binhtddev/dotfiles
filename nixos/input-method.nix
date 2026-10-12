# Input method: fcitx5 with the Unikey engine (Vietnamese).
{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = [ pkgs.qt6Packages.fcitx5-unikey ];

      # Start with the input method active. Without this, US is what you get
      # after every login and Unikey only comes on with the toggle hotkey.
      # Both keys toggle between US and Unikey: Ctrl+Space (habit) and
      # Win+Space. Key lists are indexed entries in fcitx5's config
      # ("Hotkey/TriggerKeys"."0"); a plain "TriggerKeys=..." string parses as
      # an empty list. The default Super+space group switch is cleared so it
      # does not collide with the Win+Space trigger.
      settings.globalOptions = {
        "Behavior".ActiveByDefault = true;
        "Hotkey/TriggerKeys" = {
          "0" = "Control+space";
          "1" = "Super+space";
        };
        "Hotkey/EnumerateGroupForwardKeys" = { };
      };

      # US layout plus Unikey, Unikey selected by default
      # (writes /etc/xdg/fcitx5/profile).
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "unikey";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "unikey";
      };

      # Keep a user-side ~/.config/fcitx5 from shadowing this profile.
      ignoreUserConfig = true;

      # KWin hosts the Wayland input method frontend, so only XMODIFIERS is
      # exported (XWayland apps). Keeping GTK_IM_MODULE/QT_IM_MODULE would
      # trigger fcitx5's startup warning and fight the Wayland frontend.
      waylandFrontend = true;
    };
  };
}
