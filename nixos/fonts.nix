{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      # Microsoft fonts
      corefonts
      vista-fonts

      # Desktop
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans

      # Mono
      bifont

      # Nerd
      nerd-fonts.symbols-only
    ];
    fontconfig.defaultFonts = {
      serif = [
        "Noto Serif"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Noto Sans"
        "Noto Color Emoji"
      ];
      monospace = [
        "Bifont"
        "Noto Sans Mono"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
