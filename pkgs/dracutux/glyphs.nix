# Papirus window-button marks, in Papirus's own 16x16 grid.
#
# Taken from Papirus-Dark's symbolic window icons:
#   minimize -> dash, maximize -> two corner arrows, restore -> hollow square,
#   close    -> two thick bars.
#
# Two constraints from KSvg (Aurorae's renderer) learned the hard way:
#   * a <path> with several subpaths is silently NOT painted, so every subpath
#     is a separate entry;
#   * only ONE transform group per state element, otherwise boundsOnElement()
#     mis-scales the whole element (circle included).
# `restore`'s hole relies on subpath winding, so it is a stroked rect instead.
{
  scale = 1.8; # 16-unit grid -> 36-unit button canvas
  offset = 3.6; # (36 - 16 * 1.8) / 2, centres the grid in the canvas

  # (8,8) is the grid centre; r=9 -> 90% of the button, like Breeze.
  circle = {
    cx = 8;
    cy = 8;
    r = 9;
  };

  restoreRect = {
    x = 5.25;
    y = 5.25;
    width = 5.5;
    height = 5.5;
    rx = 1;
    strokeWidth = 2.5;
  };

  marks = {
    # Papirus draws this 3 units low in its grid; shifted up so it sits centred.
    minimize = [ "M 5 7 L 5 9 L 11 9 L 11 7 Z" ];

    maximize = [
      "M 7,4 C 7,4 7,6 9,6 H 9.5 C 9.777,6 10,6.223 10,6.5 V 7 C 10,9 12,9 12,9 V 5 C 12,4.446 11.554,4 11,4 Z"
      "M 4,7 V 11 C 4,11.554 4.446,12 5,12 H 9 C 9,12 9,10 7,10 H 6.5 C 6.223,10 6,9.777 6,9.5 V 9 C 5.9681,7.1377 4,7 4,7 Z"
    ];

    close = [
      "M 5,4 C 4.4477,4 4,4.4477 4,5 4,5.2652 4.1055,5.5195 4.293,5.707 L 10.293,11.707 C 10.48,11.895 10.735,12 11,12 11.552,12 12,11.552 12,11 12,10.735 11.895,10.48 11.707,10.293 L 5.707,4.293 C 5.5195,4.1055 5.2652,4 5,4 Z"
      "M 5,12 C 4.4477,12 4,11.552 4,11 4,10.735 4.1055,10.48 4.293,10.293 L 10.293,4.293 C 10.48,4.105 10.735,4 11,4 11.552,4 12,4.448 12,5 12,5.265 11.895,5.52 11.707,5.707 L 5.707,11.707 C 5.5195,11.895 5.2652,12 5,12 Z"
    ];
  };
}
