{
  config,
  pkgs,
  ...
}:
let
  username = "binhtd";
  homeDirectory = "/home/${username}";
in
{
  # You can import other home-manager modules here
  imports = [
    # Modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ../../home/alacritty.nix
    ../../home/fish.nix
    ../../home/fonts.nix
    ../../home/git.nix
    ../../home/ghostty.nix
    ../../home/helix.nix
    ../../home/lazygit.nix
    ../../home/neovim.nix
    ../../home/ripgrep.nix
    ../../home/yazi.nix
    ../../home/zellij.nix

    ../../home/desktop.nix
    ../../home/fuzzel.nix
    # ../../home/i3status.nix
    ../../home/mako.nix
    ../../home/niri.nix
    ../../home/swaylock.nix
    ../../home/systemd/eye-strain.nix
    ../../home/waybar.nix
    ../../home/wpaperd.nix

    ../../home/dev/go.nix
    ../../home/dev/moonbit.nix
    ../../home/dev/python.nix
    # ../../home/dev/rust.nix
    ../../home/dev/tree-sitter.nix
    ../../home/dev/zig.nix
  ];

  programs = {
    # Enable home-manager and git
    home-manager.enable = true;

    # programs.helix.defaultEditor = true;
    neovim.defaultEditor = true;

    bash.enable = true;
    eza.enable = true;
    zoxide.enable = true;
    # git = {
    #   settings = {
    #     core.editor = "code --wait";
    #   };
    # };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  nixpkgs.config.allowUnfree = true;

  home = {
    inherit username homeDirectory;
    shellAliases = {
      mknixos = "nixos-rebuild switch --flake ${homeDirectory}/dotfiles#yugi --sudo";
      mkhome = "home-manager switch --flake ${homeDirectory}/dotfiles#yugi";
      mknews = "home-manager news --flake ${homeDirectory}/dotfiles#yugi";
    };
    sessionVariables = {
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1;
      NIXOS_OZONE_WL = "1";
    };
    sessionPath = [
      "$HOME/.local/bin"
    ];
    packages = with pkgs; [
      ### Browser
      # brave
      google-chrome
      ### Mail
      thunderbird
      ### Learning
      exercism
      ### Office
      libreoffice
      ### Media
      mpv
      # vimiv-qt
      ### Utils
      inkscape
      gimp
      edir
      steam-run
      vscode
      lefthook
      vim
      nerd-font-patcher
      # python313Packages.opentype-feature-freezer
      dragon-drop
      ### Dev Yaml
      yaml-language-server
      ### Dev C/C++
      clang-tools
      gcc
      ### Dev Nix
      nil
      nixfmt
      statix
      ### Dev toml
      taplo
      ### Dev markdown
      marksman
      ### Dev Node
      # bun
      pnpm
      nodejs
      ### Dev Html/Css/Json/JS
      vscode-langservers-extracted
      typescript
      typescript-language-server
      emmet-language-server
      ### Web Formatter
      # biome
      # nodePackages.prettier
    ];

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.
  };
  lib.file.mkDotfilesSymlink = link: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${link}";
    force = true;
  };
}
