// ignore_for_file: constant_identifier_names, camel_case_types, file_names
//
// The names in this file are not cosmetic. `Environment.toJson`/`fromJson`
// persist these enums via `toString()`, so the stored config of every existing
// installation literally contains strings like "SOFTWARE_MANAGERS.SNAP".
// Renaming the type or its members would make `firstWhere` fail to match on
// the next start. A rename needs a config migration first; until then the
// lint stays suppressed here rather than project-wide.
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
