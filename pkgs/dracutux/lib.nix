# Small helpers shared by the Dracutux theme generators.
{ lib }:
rec {
  # "#112233" -> 0x112233
  hexToInt =
    hex:
    let
      digits = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
      chars = lib.stringToCharacters (lib.toLower (lib.removePrefix "#" hex));
    in
    builtins.foldl' (acc: c: acc * 16 + digits.${c}) 0 chars;

  # "#112233" -> "17,34,51" (KDE colour scheme format)
  rgb =
    hex:
    let
      value = hexToInt hex;
      r = value / 65536;
      g = value / 256 - r * 256;
      b = value - (value / 256) * 256;
    in
    "${toString r},${toString g},${toString b}";

  # Convert hex colours in every .svg in `dir` using a { from = to; } map.
  recolorSvg =
    dir: mapping:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (from: to: ''
        find ${dir} -type f -name '*.svg' -exec sed -i 's|${from}|${to}|g' {} +
      '') mapping
    );
}
