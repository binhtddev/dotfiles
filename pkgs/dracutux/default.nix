_: # Variant metadata for the Dracutux theme family.
#
# Dark ("Dracutux") is the default, day ("Dracutux-Day") is the light one.
# The actual assets are built by arc-kde.nix (KDE) and arc-gtk.nix (GTK).
let
  palette = import ./palette.nix;
in
{
  variants = {
    dark = {
      palette = palette.dark;
      preferDark = true;
      lookAndFeel = "com.github.binhtd.dracutux";
      plasmaStyle = "Dracutux";
      colorScheme = "Dracutux";
      aurorae = "Dracutux";
      kvantum = "Dracutux";
      iconTheme = "Dracutux";
      gtkIconTheme = "Dracutux";
      gtkTheme = "Dracutux";
    };

    day = {
      palette = palette.day;
      preferDark = false;
      lookAndFeel = "com.github.binhtd.dracutux-day";
      plasmaStyle = "Dracutux-Day";
      colorScheme = "Dracutux-Day";
      aurorae = "Dracutux-Day";
      kvantum = "Dracutux-Day";
      iconTheme = "Dracutux-Day";
      gtkIconTheme = "Dracutux-Day";
      gtkTheme = "Dracutux-Day";
    };
  };
}
