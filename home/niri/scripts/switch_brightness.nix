{ pkgs, ... }:
let
  cli = "${pkgs.brightnessctl}/bin/brightnessctl";
in
pkgs.writeShellScriptBin "switch_brightness.sh" ''
  curr=$(${cli} g)
  result=$(awk -v n="$curr" -v a="$1" -v b="$2" '
    function abs(x) {
      return (x < 0) ? -x : x
    }
    BEGIN {
      diff_a = abs(n - a)
      diff_b = abs(n - b)

      if (diff_a < diff_b) {
        print b
      } else {
        print a
      }
    }
  ')
  ${cli} set $result
  exit 0
''
