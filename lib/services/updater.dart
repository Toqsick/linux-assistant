import 'package:linux_assistant/enums/distros.dart';
import 'package:linux_assistant/enums/softwareManagers.dart';
import 'package:linux_assistant/main.dart';
import 'package:linux_assistant/models/linux_command.dart';
import 'package:linux_assistant/services/config_handler.dart';
import 'package:linux_assistant/services/linux.dart';

class LinuxAssistantUpdater {
  static Map? newestVersionInformation;

  /// Only searches, if the last successful search is 7 days old, otherwise returns false;
  static bool isNewerVersionAvailable() {
    // Lookup done by WeeklyTasks

    // If we are running as flatpak we don't need to check for updates manually.
    if (Linux.currentenvironment.runningInFlatpak) {
      return false;
    }

    // Return false if we are running on Arch Linux and the user has it not running in flatpak.
    // We are missing an update mechanism for Arch Linux at the current time.
    if (!Linux.currentenvironment.runningInFlatpak &&
        [DISTROS.ARCH, DISTROS.MANJARO, DISTROS.ENDEAVOUR]
            .contains(Linux.currentenvironment.distribution)) {
      return false;
    }

    String newestVersion = ConfigHandler().getValueUnsafe(
        "newest-linux-assistant-version", CURRENT_LINUX_ASSISTANT_VERSION);

    // If reading the version file failed, just return false. Else the version
    // check will crash.
    return CURRENT_LINUX_ASSISTANT_VERSION.isEmpty
        ? false
        : isVersionGreaterThanCurrent(newestVersion);
  }

  /// example for [version] would be: "3.4.19"
  ///
  /// Tolerates shapes other than exactly `x.y.z`. This used to assert on the
  /// component count and `int.parse` each part, so a release tagged `0.8` or
  /// `v0.8.0-rc1` threw instead of simply reporting "no update".
  static bool isVersionGreaterThanCurrent(String version) {
    final List<int> current = _parseVersion(CURRENT_LINUX_ASSISTANT_VERSION);
    final List<int> other = _parseVersion(version);

    if (current.isEmpty || other.isEmpty) {
      return false;
    }

    final int length = current.length > other.length ? current.length : other.length;
    for (int i = 0; i < length; i++) {
      final int a = i < other.length ? other[i] : 0;
      final int b = i < current.length ? current[i] : 0;
      if (a != b) {
        return a > b;
      }
    }
    // If they are equal return false.
    return false;
  }

  /// Turns "v1.2.3", "1.2" or "1.2.3-rc1" into its numeric components.
  /// Returns an empty list when nothing numeric can be read at all.
  static List<int> _parseVersion(String version) {
    final List<int> parts = [];
    for (final String raw in version.trim().replaceFirst("v", "").split(".")) {
      final match = RegExp(r"^\d+").firstMatch(raw.trim());
      if (match == null) {
        break;
      }
      parts.add(int.parse(match.group(0)!));
    }
    return parts;
  }

  /// Only adds commands to Linux.commandQueue.
  static void updateLinuxAssistantToNewestVersion() {
    assert(newestVersionInformation != null);
    for (Map asset in newestVersionInformation!["assets"]) {
      // Debian based systems
      if (asset["content_type"] == "application/vnd.debian.binary-package" &&
          Linux.usesCurrentEnvironmentDebPackages()) {
        String downloadURL = asset["browser_download_url"];
        if (downloadURL.isEmpty) {
          print(
              "Error while updating Linux-Assistant to newest version. Download URL empty.");
          return;
        }
        String fileName = downloadURL.split("/").last;
        Linux.commandQueue.add(LinuxCommand(
            userId: Linux.currentenvironment.currentUserId,
            command: "wget $downloadURL -P /tmp/"));
        Linux.commandQueue.add(LinuxCommand(
            userId: 0, command: "/usr/bin/apt install /tmp/$fileName -y"));
      }
      // RPM
      if (asset["content_type"] == "application/x-rpm" &&
          Linux.usesCurrentEnvironmentRPMPackages()) {
        String downloadURL = asset["browser_download_url"];
        if (downloadURL.isEmpty) {
          print(
              "Error while updating Linux-Assistant to newest version. Download URL empty.");
          return;
        }
        String fileName = downloadURL.split("/").last;
        Linux.commandQueue.add(LinuxCommand(
            userId: Linux.currentenvironment.currentUserId,
            command: "wget $downloadURL -P /tmp/"));
        if (Linux.currentenvironment.installedSoftwareManagers
            .contains(SOFTWARE_MANAGERS.ZYPPER)) {
          Linux.commandQueue.add(LinuxCommand(
              userId: 0,
              command:
                  "${Linux.getExecutablePathOfSoftwareManager(SOFTWARE_MANAGERS.ZYPPER)} --non-interactive  --no-gpg-checks install /tmp/$fileName"));
        }
        if (Linux.currentenvironment.installedSoftwareManagers
            .contains(SOFTWARE_MANAGERS.DNF)) {
          Linux.commandQueue.add(LinuxCommand(
              userId: 0,
              command:
                  "${Linux.getExecutablePathOfSoftwareManager(SOFTWARE_MANAGERS.DNF)} install /tmp/$fileName -y"));
        }
      }
    }
  }
}
