{
  pkgs ? import <nixpkgs>,
}:
let
  pname = "bifont";
  version = "0.0";
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchzip {
    url = "https://github.com/binhtddev/bifont/archive/refs/tags/v${version}.zip";
    sha256 = "sha256-a7nkIBrVzfLZ6gn1r/zs9YbFfeRG7C3/33lwkOl3wjw=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 ${pname}-${version}/*.ttf -t $out/share/fonts/truetype
    runHook postInstall
  '';
}
