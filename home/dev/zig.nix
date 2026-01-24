{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      zig_0_15
      zls_0_15
    ];
  };
}
