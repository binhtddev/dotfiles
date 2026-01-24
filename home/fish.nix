{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings
    '';
    functions = {
      fish_default_mode_prompt = {
        description = "Display vi/helix prompt mode";
        body = builtins.readFile ./fish/fish_default_mode_prompt.fish;
      };
      fish_helix_key_bindings = {
        description = "helix-like key bindings for fish";
        body = builtins.readFile ./fish/fish_helix_key_bindings.fish;
      };
    };
  };
}
