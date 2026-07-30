enum DESKTOPS {
  GNOME,
  CINNAMON,
  KDE,
  XFCE,
}

String getNiceStringOfDesktopsEnum(var desktop) {
  switch (desktop) {
    case DESKTOPS.GNOME:
      return "Gnome";
    case DESKTOPS.CINNAMON:
      return "Cinnamon";
    case DESKTOPS.KDE:
      return "KDE";
    case DESKTOPS.XFCE:
      return "Xfce";
    default:
      return "";
  }
}

/// Reads a [DESKTOPS] back from its stored name.
///
/// Accepts both the plain name ("GNOME", what the settings screen writes) and
/// the legacy `toString()` form ("DESKTOPS.GNOME"), and falls back rather than
/// throwing — same reasoning as `getEnumFromString` for distributions.
DESKTOPS getDektopEnumOfString(str) {
  final String value = str.toString();
  return DESKTOPS.values.firstWhere(
    (e) => e.name == value || e.toString() == value,
    orElse: () => DESKTOPS.GNOME,
  );
}
