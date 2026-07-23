{
  pkgs,
  config,
  ...
}:
{
  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = false;
    extraPackages = with pkgs; [
      ### plugins installer
      gnumake
      git
      unzip
      ### treesitter
      tree-sitter
      gcc
      ### telescope
      ripgrep
      fzf
      fd
      ### typescript-tools
      # nodejs
      # typescript
    ];
  };

  home.file."${config.xdg.configHome}/nvim" = config.lib.file.mkDotfilesSymlink "home/nvim";
}
