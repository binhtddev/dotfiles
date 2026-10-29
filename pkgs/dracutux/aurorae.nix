# Aurorae window decoration assets: Arc titlebar with Papirus's window marks,
# coloured with a Dracutux palette.
#
# Geometry follows kdecoration/breezebutton.cpp (20-unit box, 18-unit highlight
# circle) but the marks come from Papirus's symbolic window icons, which live in
# a 16x16 grid. `glyphs.nix` documents the two KSvg constraints (no multi-subpath
# paths, one transform group per state).
#
# Colours are Dracutux, not Breeze's "invert the titlebar" trick: the highlight
# is a neutral shade of the titlebar and the mark keeps the text colour, so the
# dark theme stays dark on hover. Close highlights red with a light mark.
{ rgb }:
p:
let
  inherit (import ./glyphs.nix)
    scale
    offset
    circle
    restoreRect
    marks
    ;

  box = ''<rect x="0" y="0" width="36" height="36" style="opacity:0.001"/>'';

  mark =
    kind: color:
    if kind == "restore" then
      ''<rect x="${toString restoreRect.x}" y="${toString restoreRect.y}" width="${toString restoreRect.width}" height="${toString restoreRect.height}" rx="${toString restoreRect.rx}" fill="none" stroke="${color}" stroke-width="${toString restoreRect.strokeWidth}"/>''
    else
      builtins.concatStringsSep "" (map (d: ''<path d="${d}" fill="${color}"/>'') marks.${kind});

  highlight =
    color:
    ''<circle cx="${toString circle.cx}" cy="${toString circle.cy}" r="${toString circle.r}" fill="${color}"/>'';

  # One transform group per state: circle and mark share the grid coordinate
  # system, exactly like the working (verified) scratch theme.
  state =
    id: kind: color: bg:
    "<g id=\"${id}\">${box}<g transform=\"translate(${toString offset},${toString offset}) scale(${toString scale})\">"
    + (if bg == null then "" else highlight bg)
    + mark kind color
    + "</g></g>";

  button =
    {
      kind,
      circle,
      markColor,
      pressedCircle,
      pressedMarkColor,
    }:
    ''
      <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 36 36" version="1.1">
      ${state "active-center" kind markColor null}
      ${state "hover-center" kind markColor circle}
      ${state "pressed-center" kind pressedMarkColor pressedCircle}
      ${state "inactive-center" kind p.inactive_fg null}
      ${state "deactivated-center" kind p.disabled_fg null}
      </svg>
    '';

  # Neutral highlight (no accent hue), mark keeps the text colour.
  regular =
    kind:
    button {
      inherit kind;
      circle = p.button_hover;
      markColor = p.text;
      pressedCircle = p.button_active;
      pressedMarkColor = p.text;
    };

  # Close uses the negative colour for the highlight and a light mark on top.
  close = button {
    kind = "close";
    circle = p.red;
    markColor = p.on_close;
    pressedCircle = p.red_dark;
    pressedMarkColor = p.on_close;
  };
in
{
  inherit close;
  maximize = regular "maximize";
  minimize = regular "minimize";
  restore = regular "restore";

  rc = ''
    [General]
    ActiveFocusedTabColor=${rgb p.purple}
    ActiveTextColor=${rgb p.text}
    ActiveTextShadowColor=0,0,0,0
    ActiveUnfocusedTabColor=${rgb p.window}
    Animation=1
    InactiveFocusedTabColor=${rgb p.purple_dark}
    InactiveTextColor=${rgb p.inactive_fg}
    InactiveTextShadowColor=0,0,0,0
    InactiveUnfocusedTabColor=${rgb p.window_alt}
    LeftButtons=
    RightButtons=IAX
    Shadow=false
    TextShadowOffsetX=0
    TextShadowOffsetY=0
    TitleAlignment=Center
    TitleVerticalAlignment=Center
    UseTextShadow=false

    # 26px buttons, 10px spacing. Centring rule from decorationtheme.cpp:
    #   titleArea = max(TitleHeight, ButtonHeight + ButtonMarginTop)
    #   buttonTop = TitleEdgeTop + ButtonMarginTop
    # so TitleHeight must be ButtonHeight + 2*ButtonMarginTop, with symmetric
    # TitleEdgeTop/Bottom, otherwise the highlight circle sits high/low.
    [Layout]
    BorderBottom=1
    BorderLeft=1
    BorderRight=1
    ButtonHeight=26
    ButtonMarginTop=4
    ButtonSpacing=10
    ButtonWidth=26
    ExplicitButtonSpacer=10
    PaddingBottom=10
    PaddingLeft=10
    PaddingRight=10
    PaddingTop=10
    TitleBorderLeft=1
    TitleBorderRight=1
    TitleEdgeBottom=2
    TitleEdgeBottomMaximized=2
    TitleEdgeLeft=4
    TitleEdgeLeftMaximized=4
    TitleEdgeRight=4
    TitleEdgeRightMaximized=4
    TitleEdgeTop=2
    TitleEdgeTopMaximized=2
    TitleHeight=34
  '';
}
