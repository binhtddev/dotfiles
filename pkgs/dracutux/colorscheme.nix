# Renders a KDE colour scheme (.colors) from a Dracutux palette.
{ rgb }:
p:
let
  # A regular colour group: `fg` on top of `bg`/`alt`.
  group = name: bg: alt: fg: ''
    [Colors:${name}]
    BackgroundAlternate=${rgb alt}
    BackgroundNormal=${rgb bg}
    DecorationFocus=${rgb p.purple}
    DecorationHover=${rgb p.purple}
    ForegroundActive=${rgb p.cyan}
    ForegroundInactive=${rgb p.inactive_fg}
    ForegroundLink=${rgb p.blue}
    ForegroundNegative=${rgb p.red}
    ForegroundNeutral=${rgb p.yellow}
    ForegroundNormal=${rgb fg}
    ForegroundPositive=${rgb p.green}
    ForegroundVisited=${rgb p.pink}
  '';

  # Selection group: text sits on the purple accent.
  selection = ''
    [Colors:Selection]
    BackgroundAlternate=${rgb p.purple_dark}
    BackgroundNormal=${rgb p.purple}
    DecorationFocus=${rgb p.purple}
    DecorationHover=${rgb p.purple}
    ForegroundActive=${rgb p.on_accent}
    ForegroundInactive=${rgb p.on_accent}
    ForegroundLink=${rgb p.on_accent}
    ForegroundNegative=${rgb p.on_accent}
    ForegroundNeutral=${rgb p.on_accent}
    ForegroundNormal=${rgb p.on_accent}
    ForegroundPositive=${rgb p.on_accent}
    ForegroundVisited=${rgb p.on_accent}
  '';
in
''
  [ColorEffects:Disabled]
  Color=${rgb p.disabled_fg}
  ColorAmount=0
  ColorEffect=0
  ContrastAmount=0.65
  ContrastEffect=1
  IntensityAmount=0.1
  IntensityEffect=2

  [ColorEffects:Inactive]
  ChangeSelectionColor=true
  Color=${rgb p.inactive_fg}
  ColorAmount=0.025
  ColorEffect=2
  ContrastAmount=0.1
  ContrastEffect=2
  Enable=false
  IntensityAmount=0
  IntensityEffect=0

  ${group "Button" p.control p.button_alt p.text}

  ${group "Complementary" p.window p.window_alt p.text}

  ${group "Header" p.window p.window_alt p.text}

  ${selection}

  ${group "Tooltip" p.window p.window_alt p.text}

  ${group "View" p.view p.view_alt p.text}

  ${group "Window" p.window p.window_alt p.text}

  [General]
  ColorScheme=${p.name}
  Name=${p.name}
  shadeSortColumn=true

  [KDE]
  contrast=4

  [WM]
  activeBackground=${rgb p.window}
  activeBlend=${rgb p.window}
  activeForeground=${rgb p.text}
  inactiveBackground=${rgb p.window}
  inactiveBlend=${rgb p.window}
  inactiveForeground=${rgb p.inactive_fg}
''
