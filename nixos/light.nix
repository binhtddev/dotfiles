{ pkgs, ... }:
{
  # Brightness: need "video" in user extraGroups
  # programs.light = {
  #   enable = true;
  #   brightnessKeys.enable = true;
  # };
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
