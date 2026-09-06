// ignore_for_file: constant_identifier_names, camel_case_types, file_names
//
// The names in this file are not cosmetic. `Environment.toJson`/`fromJson`
// persist these enums via `toString()`, so the stored config of every existing
// installation literally contains strings like "SOFTWARE_MANAGERS.SNAP".
// Renaming the type or its members would make `firstWhere` fail to match on
// the next start. A rename needs a config migration first; until then the
// lint stays suppressed here rather than project-wide.
enum BROWSERS {
  FIREFOX,
  CHROMIUM,
  CHROME,
  EDGE,
  BRAVE,
  OPERA,
  LIBREWOLF,
  WATERFOX,
  TORBROWSER,
}

BROWSERS getBrowserEnumOfString(str) {
  return BROWSERS.values.firstWhere((e) => e.toString() == str);
}
