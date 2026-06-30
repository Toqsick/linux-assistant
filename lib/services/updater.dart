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
    if (Linux.currentenvironment.runningInFlatpak) {
      return false;
    }

    if (!Linux.currentenvironment.runningInFlatpak &&
        [DISTROS.ARCH, DISTROS.MANJARO, DISTROS.ENDEAVOUR]
            .contains(Linux.currentenvironment.distribution)) {
      return false;
    }

    String newestVersion = ConfigHandler().getValueUnsafe(
        "newest-linux-assistant-version", CURRENT_LINUX_ASSISTANT_VERSION);

    return CURRENT_LINUX_ASSISTANT_VERSION.isEmpty
        ? false
        : isVersionGreaterThanCurrent(newestVersion);
  }

  /// example for [version] would be: "0.7.0"
  static bool isVersionGreaterThanCurrent(String version) {
    // P1: validate format before parsing — assert() is stripped in release builds
    // and int.parse("") would throw FormatException on malformed API responses.
    List<String> currentVersionList =
        CURRENT_LINUX_ASSISTANT_VERSION.split(".");
    List<String> versionList = version.split(".");

    if (currentVersionList.length != 3 || versionList.length != 3) {
      print(
          "Warning: malformed version string — current: $CURRENT_LINUX_ASSISTANT_VERSION, remote: $version");
      return false;
    }

    for (int i = 0; i < 3; i++) {
      final current = int.tryParse(currentVersionList[i]);
      final remote = int.tryParse(versionList[i]);
      if (current == null || remote == null) {
        print("Warning: non-numeric version segment at index $i — skipping update check.");
        return false;
      }
      if (remote > current) return true;
      if (remote < current) return false;
    }
    return false;
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
        // P2: prefer curl over wget — curl is available on more distros by default.
        // Falls back to wget if curl is not found.
        Linux.commandQueue.add(LinuxCommand(
            userId: Linux.currentenvironment.currentUserId,
            command:
                "curl -fL '$downloadURL' -o /tmp/$fileName || wget '$downloadURL' -O /tmp/$fileName"));
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
        // P2: prefer curl over wget
        Linux.commandQueue.add(LinuxCommand(
            userId: Linux.currentenvironment.currentUserId,
            command:
                "curl -fL '$downloadURL' -o /tmp/$fileName || wget '$downloadURL' -O /tmp/$fileName"));
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
