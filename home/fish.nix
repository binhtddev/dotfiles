{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_helix_key_bindings
    '';
    functions = {
      fish_default_mode_prompt = {
        description = "Display vi/helix prompt mode";
        body = builtins.readFile ./fish/functions/fish_default_mode_prompt.fish;
      };
      fish_helix_key_bindings = {
        description = "helix-like key bindings for fish";
        body = builtins.readFile ./fish/functions/fish_helix_key_bindings.fish;
      };
    };
    plugins = [
      {
        name = "frozen_theme";
        src = ./fish/conf.d/fish_frozen_theme.fish;
      }
    ];
  };
}
