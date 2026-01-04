{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      gcc # for cargo build
      wasm-tools
      wasm-pack
      wasm-bindgen-cli
      binaryen
      cargo-binstall

      rustup

      ## alternative
      # cargo
      # rustc
      # rust-analyzer
      # rustfmt
      # wit-bindgen
    ];
    sessionVariables = {
      RUSTUP_AUTO_INSTALL = 0;
    };
    sessionPath = [
      "$HOME/.cargo/bin"
    ];
  };
}
