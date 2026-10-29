# Dracutux colour palette.
#
# The raw colours mirror the helix themes in home/helix/themes:
#   dracutux.toml     -> dark
#   dracutux_day.toml -> day
#
# The extra tokens below are the translation layer for KDE/GTK/Kvantum:
# helix only has semantic syntax colours, desktop themes also need window,
# view, button and border shades.
{
  dark = {
    name = "Dracutux";

    # helix palette
    base = "#222233";
    ui_base = "#111122";
    text = "#ffffee";
    subtle_text = "#bbbbcc";
    selection = "#443377";
    ui_selection = "#444455";
    comment = "#6677aa";
    cyan = "#88eeff";
    blue = "#66bbff";
    green = "#55ff77";
    teal = "#55ddcc";
    pink = "#ff77cc";
    purple = "#bb99ff";
    red = "#ff5555";
    yellow = "#eeff88";
    orange = "#ffbb77";

    # derived shades
    purple_dark = "#8f6fd6";
    red_dark = "#cc3b3b";
    # neutral button highlight (no accent hue on hover)
    button_hover = "#2a2a3f";
    button_active = "#3a3a55";
    # Qt/KDE control face (colour-scheme [Colors:Button] background). It has to
    # stay clear of both the window and the grooves the QQC2 style derives from
    # it, otherwise switch knobs, slider handles and checkbox boxes vanish.
    # Arc drove these from #414857 on a #2f343f window; our window is far
    # darker (#111122), so the face needs a lighter shade to keep the contrast.
    control = "#3a3a55";
    on_close = "#ffffee";
    window = "#111122";
    window_alt = "#1a1a2c";
    view = "#222233";
    view_alt = "#26263a";
    button = "#222233";
    button_alt = "#2a2a3f";
    border = "#33334a";
    inactive_fg = "#6677aa";
    disabled_fg = "#444455";
    shadow = "#05050c";
    on_accent = "#222233";

    # helix only defines these hues as foregrounds; each gets a matching
    # background (the window tinted towards the hue) for badges, syntax
    # backgrounds and other tinted surfaces.
    comment_bg = "#242740";
    cyan_bg = "#2b4253";
    blue_bg = "#243653";
    green_bg = "#204535";
    teal_bg = "#203e47";
    pink_bg = "#452747";
    purple_bg = "#362f53";
    red_bg = "#45202d";
    yellow_bg = "#424538";
    orange_bg = "#453635";
  };

  day = {
    name = "Dracutux-Day";

    # helix palette
    base = "#eeeeff";
    ui_base = "#ffffff";
    text = "#444433";
    subtle_text = "#777788";
    selection = "#ddccff";
    ui_selection = "#ccccdd";
    comment = "#aabbee";
    cyan = "#448899";
    blue = "#4477cc";
    green = "#33aa55";
    teal = "#339977";
    pink = "#bb5588";
    purple = "#7744bb";
    red = "#ee4444";
    yellow = "#778822";
    orange = "#aa6633";

    # derived shades
    purple_dark = "#5c3399";
    red_dark = "#c22c2c";
    # neutral button highlight (no accent hue on hover)
    button_hover = "#ececf9";
    button_active = "#dcdcf0";
    # Qt/KDE control face, see the dark palette. In the day theme the grooves
    # stay light, so the near-white face keeps its contrast there.
    control = "#f6f6ff";
    on_close = "#ffffff";
    window = "#ffffff";
    window_alt = "#f6f6fc";
    view = "#eeeeff";
    view_alt = "#e8e8f7";
    button = "#f6f6ff";
    button_alt = "#ececf9";
    border = "#d8d8e8";
    inactive_fg = "#777788";
    disabled_fg = "#ccccdd";
    shadow = "#c8c8d8";
    on_accent = "#ffffff";

    # helix only defines these hues as foregrounds; each gets a matching
    # background (the window tinted towards the hue) for badges, syntax
    # backgrounds and other tinted surfaces.
    comment_bg = "#f0f3fc";
    cyan_bg = "#ddeaed";
    blue_bg = "#dde7f6";
    green_bg = "#daf0e0";
    teal_bg = "#daede7";
    pink_bg = "#f3e0ea";
    purple_bg = "#e7ddf3";
    red_bg = "#fcdddd";
    yellow_bg = "#e7ead7";
    orange_bg = "#f0e3da";
  };
}
