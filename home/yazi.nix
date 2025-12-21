{ config, ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };
  home.file."${config.xdg.configHome}/yazi" = {
    source = ./yazi;
    recursive = true;
  };
}
