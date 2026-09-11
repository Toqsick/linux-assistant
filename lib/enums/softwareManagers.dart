// ignore_for_file: constant_identifier_names, camel_case_types, file_names
//
// The names in this file are not cosmetic. `Environment.toJson`/`fromJson`
// persist these enums via `toString()`, so the stored config of every existing
// installation literally contains strings like "SOFTWARE_MANAGERS.SNAP".
// Renaming the type or its members would make `firstWhere` fail to match on
// the next start. A rename needs a config migration first; until then the
// lint stays suppressed here rather than project-wide.
enum SOFTWARE_MANAGERS {
  FLATPAK,
  SNAP,
  APT,
  ZYPPER,
  DNF,
  PACMAN,
}

String getNiceStringOfSoftwareManagerEnum(SOFTWARE_MANAGERS input) {
  switch (input) {
    case SOFTWARE_MANAGERS.FLATPAK:
      return "Flatpak";
    case SOFTWARE_MANAGERS.SNAP:
      return "Snap";
    case SOFTWARE_MANAGERS.APT:
      return "APT";
    case SOFTWARE_MANAGERS.ZYPPER:
      return "Zypper";
    case SOFTWARE_MANAGERS.DNF:
      return "DNF";
    case SOFTWARE_MANAGERS.PACMAN:
      return "Pacman";
  }
}

SOFTWARE_MANAGERS getSoftwareManagerEnumOfString(str) {
  return SOFTWARE_MANAGERS.values.firstWhere((e) => e.toString() == str);
}
