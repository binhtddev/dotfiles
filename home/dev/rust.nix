{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    gcc # for cargo build

    ## alternative
    # cargo
    # rustc
    # rust-analyzer
    # rustfmt
    # wit-bindgen
    # wasm-tools
  ];
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
}
