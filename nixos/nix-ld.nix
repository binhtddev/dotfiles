{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    # OpenTUI's native clipboard dlopen()s libwayland-client.so.0 by name.
    # Without it the Wayland backend is dropped and the TUI falls back to X11,
    # where the clipboard is empty on a Wayland session (Ctrl+V pastes nothing).
    # See opencode issues #55639 / #48931.
    libraries = [ pkgs.wayland ];
  };
}
