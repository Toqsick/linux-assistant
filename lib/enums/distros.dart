// ignore_for_file: constant_identifier_names, camel_case_types, file_names
//
// The names in this file are not cosmetic. `Environment.toJson`/`fromJson`
// persist these enums via `toString()`, so the stored config of every existing
// installation literally contains strings like "SOFTWARE_MANAGERS.SNAP".
// Renaming the type or its members would make `firstWhere` fail to match on
// the next start. A rename needs a config migration first; until then the
// lint stays suppressed here rather than project-wide.
enum DISTROS {
  UBUNTU,
  LINUX_MINT,
  DEBIAN,
  POPOS,
  MXLINUX,
  ZORINOS,
  KDENEON,
  OPENSUSE,
  LMDE,
  FEDORA,
  ARCH,
  MANJARO,
  ENDEAVOUR,
}

String getNiceStringOfDistrosEnum(var distro) {
  switch (distro) {
    case DISTROS.UBUNTU:
      return "Ubuntu";
    case DISTROS.LINUX_MINT:
      return "Linux Mint";
    case DISTROS.DEBIAN:
      return "Debian";
    case DISTROS.POPOS:
      return "Pop!_OS";
    case DISTROS.MXLINUX:
      return "MX Linux";
    case DISTROS.ZORINOS:
      return "Zorin OS";
    case DISTROS.KDENEON:
      return "KDE neon";
    case DISTROS.OPENSUSE:
      return "openSUSE";
    case DISTROS.LMDE:
      return "LMDE";
    case DISTROS.FEDORA:
      return "Fedora";
    case DISTROS.ARCH:
      return "Arch";
    case DISTROS.MANJARO:
      return "Manjaro";
    case DISTROS.ENDEAVOUR:
      return "EndeavourOS";
    default:
      return "";
  }
}

/// Reads a [DISTROS] back from its stored name.
///
/// Falls back to Debian instead of throwing: the value comes from the user's
/// config file, and an unknown one there used to abort startup with a
/// `StateError` — leaving no way to reach the setting that caused it.
DISTROS getEnumFromString(String str) {
  return DISTROS.values.firstWhere(
    (e) => e.name == str,
    orElse: () => DISTROS.DEBIAN,
  );
}
