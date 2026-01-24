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
      maple-mono.NF

      # Nerd
      nerd-fonts.symbols-only
    ];
  };
}
