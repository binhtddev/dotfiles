# GTK headerbar buttons using Papirus's window marks, coloured with a Dracutux
# palette. Same geometry/colours as the Aurorae decoration, so KDE and GTK
# windows match.
#
#   normal   mark in the text colour
#   hover    neutral highlight circle, mark still in the text colour
#   pressed  slightly stronger highlight
#   backdrop dimmed mark
# Close uses the negative colour behind a light mark.
p:
let
  inherit (import ../glyphs.nix)
    scale
    offset
    circle
    restoreRect
    marks
    ;

  kinds = [
    "close"
    "minimize"
    "maximize"
  ];

  states = [
    {
      state = "";
      file = "";
      kind = "plain";
    }
    {
      state = ":hover";
      file = "-hover";
      kind = "hover";
    }
    {
      state = ":active";
      file = "-active";
      kind = "active";
    }
    {
      state = ":backdrop";
      file = "-backdrop";
      kind = "backdrop";
    }
  ];

  colors = kind: {
    hover = {
      circle = if kind == "close" then p.red else p.button_hover;
      stroke = if kind == "close" then p.on_close else p.text;
    };
    active = {
      circle = if kind == "close" then p.red_dark else p.button_active;
      stroke = if kind == "close" then p.on_close else p.text;
    };
  };

  glyph =
    kind: color:
    if kind == "restore" then
      ''<rect x="${toString restoreRect.x}" y="${toString restoreRect.y}" width="${toString restoreRect.width}" height="${toString restoreRect.height}" rx="${toString restoreRect.rx}" fill="none" stroke="${color}" stroke-width="${toString restoreRect.strokeWidth}"/>''
    else
      builtins.concatStringsSep "" (map (d: ''<path d="${d}" fill="${color}"/>'') marks.${kind});

  highlight =
    color:
    ''<circle cx="${toString circle.cx}" cy="${toString circle.cy}" r="${toString circle.r}" fill="${color}"/>'';

  svg =
    kind: state:
    let
      color =
        if state == "plain" then
          {
            circle = null;
            stroke = p.text;
          }
        else if state == "backdrop" then
          {
            circle = null;
            stroke = p.inactive_fg;
          }
        else
          (colors kind).${state};
    in
    ''
      <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36" version="1.1">
        <g transform="translate(${toString offset},${toString offset}) scale(${toString scale})">
          ${if color.circle == null then "" else highlight color.circle}
          ${glyph kind color.stroke}
        </g>
      </svg>
    '';

  files = builtins.listToAttrs (
    builtins.concatMap (
      kind:
      map (s: {
        name = "titlebutton-${kind}${s.file}.svg";
        value = svg kind s.kind;
      }) states
    ) kinds
  );

  selectors = [
    "window headerbar button.titlebutton"
    "window .titlebar button.titlebutton"
    "dialog headerbar button.titlebutton"
    "dialog .titlebar button.titlebutton"
    "headerbar button.titlebutton"
    ".titlebar button.titlebutton"
  ];

  rule =
    kind: state: file:
    builtins.concatStringsSep ",\n" (map (sel: "${sel}.${kind}${state}") selectors)
    + "\n"
    + ''
      {
        border: none;
        box-shadow: none;
        background-color: transparent;
        background-image: url("../assets-dracutux/${file}");
        background-size: 20px 20px;
        background-position: center;
        background-repeat: no-repeat;
      }
    '';

  # 24px button box with a 20px highlight, and hide the icon GTK would draw on
  # top of our background.
  box =
    builtins.concatStringsSep ",\n" (map (sel: "${sel}") selectors)
    + "\n"
    + ''
      {
        min-width: 24px;
        min-height: 24px;
        padding: 0;
        margin: 0;
      }
    ''
    + "\n"
    + builtins.concatStringsSep ",\n" (map (sel: "${sel} image") selectors)
    + "\n"
    + ''
      {
        color: transparent;
      }
    '';

  css = builtins.concatStringsSep "\n" (
    [ box ]
    ++ builtins.concatMap (
      kind: map (s: rule kind s.state "titlebutton-${kind}${s.file}.svg") states
    ) kinds
  );
in
{
  inherit files css;
}
