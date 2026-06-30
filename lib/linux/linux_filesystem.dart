import 'package:linux_assistant/services/linux.dart';

class DeviceInfo {
  final String filesystem;
  final bool isRemovable;
  final String mountPoint;
  final String size;
  final String sizeFree;
  final String sizeUsed;
  final int usedPercent;

  const DeviceInfo(this.filesystem, this.size, this.sizeUsed, this.sizeFree,
      this.usedPercent, this.mountPoint, this.isRemovable);
}

abstract class LinuxFilesystem {
  static final List<String> _ignoreDevices = [
    "dev",
    "run",
    "df:",
    "udev",
    "tmpfs",
    "/dev/loop",
    "revokefs-fuse",
    "cgroup",
    "efivarfs"
  ];

  static final List<String> _removableDevices = ["/media/", "/mnt/"];

  static Future<List<DeviceInfo>> disks() async {
    var cmdResult = await Linux.runCommandWithCustomArguments(
        "/usr/bin/df", ["-h"],
        getErrorMessages: false);

    Iterable<String> lines = cmdResult
        .split("\n")
        .skip(1)
        .where((x) => !_ignoreDevices.any((y) => x.startsWith(y)));

    lines = lines.where((element) => element.length > 10);

    var devices = List<DeviceInfo>.empty(growable: true);
    var devicesRead = List<String>.empty(growable: true);
    for (var line in lines) {
      var values = line.split(" ");
      values.removeWhere((x) => x == "");
      if (values.length < 6) continue;
      if (devicesRead.contains(values[0]) || values[1].endsWith("M")) {
        continue;
      }

      // P1: use int.tryParse — df -h can return "-" for Use% on Btrfs/overlay mounts
      final rawPercent = values[4].substring(0, values[4].length - 1);
      final usedPercent = int.tryParse(rawPercent) ?? 0;

      devices.add(DeviceInfo(
          values[0],
          values[1],
          values[2],
          values[3],
          usedPercent,
          values[5],
          _removableDevices.any((x) => values[5].contains(x))));

      devicesRead.add(values[0]);
    }

    return devices;
  }
}
