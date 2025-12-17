{
  pkgs ? import <nixpkgs>,
}:
let
  pname = "bifont";
  version = "0.0.1";
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchzip {
    url = "https://github.com/binhtddev/bifont/releases/download/v${version}/bifont.zip";
    sha256 = "sha256-5QgrFf8MuhrDBxZj2Xxvx65zG9stBc1BOCryqbPMqM8=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 *.ttf -t $out/share/fonts/truetype
    runHook postInstall
  '';
}
