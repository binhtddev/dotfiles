# Arc for KDE Plasma: plasma theme, color scheme, aurorae window decoration,
# Kvantum themes and extras, ported from the Arc GTK theme.
# Upstream: https://github.com/PapirusDevelopmentTeam/arc-kde
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "arc-kde";
  version = "unstable-2025-12-17";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "arc-kde";
    rev = "b67cdb76ccbe33bdb47e82ecbdd0eed3c0cea29e";
    hash = "sha256-WNlC2tjiuMMT4EJn2O5BPP9EUJgv/ce2hA8EWlJPC9Q=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Upstream Makefile just copies the theme dirs into $PREFIX/share.
  # Also rename the color scheme to a single token: the generated
  # `plasma-apply-colorscheme` call is unquoted and the tool only reads the
  # first positional argument, so "Arc Dark" would resolve to the wrong scheme.
  installPhase = ''
    runHook preInstall
    make install PREFIX= DESTDIR="$out"
    substituteInPlace "$out/share/color-schemes/ArcDark.colors" \
      --replace-fail "Name=Arc Dark" "Name=ArcDark"

    # Plasma 6 only loads KPackage plugins that ship metadata.json; upstream
    # still provides the Plasma 5 metadata.desktop for the global theme.
    cat > "$out/share/plasma/look-and-feel/com.github.varlesh.arc-dark/metadata.json" <<'EOF'
    {
      "KPackageStructure": "Plasma/LookAndFeel",
      "KPlugin": {
        "Authors": [
          {
            "Name": "Alexey Varfolomeev"
          }
        ],
        "Category": "",
        "Description": "Arc Dark Style",
        "Id": "com.github.varlesh.arc-dark",
        "License": "CC-BY-SA",
        "Name": "Arc Dark",
        "Website": "https://github.com/PapirusDevelopmentTeam/arc-kde"
      }
    }
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Port of the Arc GTK theme for the KDE Plasma desktop";
    homepage = "https://github.com/PapirusDevelopmentTeam/arc-kde";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
