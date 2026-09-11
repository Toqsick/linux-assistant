// Tests for the environment detection and version handling that decide how the
// app behaves on a given distribution.

import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/enums/desktops.dart';
import 'package:linux_assistant/enums/distros.dart';
import 'package:linux_assistant/main.dart';
import 'package:linux_assistant/models/environment.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/services/updater.dart';

void main() {
  group("distribution fallback via ID_LIKE", () {
    test("an unknown Ubuntu derivative resolves to Ubuntu", () {
      expect(
        Linux.distroFromIdLike("elementary", "ubuntu debian"),
        DISTROS.UBUNTU,
      );
    });

    test("the closest family wins over the later one", () {
      // ID_LIKE is ordered closest first, so "ubuntu debian" must not
      // resolve to Debian.
      expect(Linux.distroFromIdLike("", "ubuntu debian"), DISTROS.UBUNTU);
      expect(Linux.distroFromIdLike("", "debian"), DISTROS.DEBIAN);
    });

    test("ID alone is enough", () {
      expect(Linux.distroFromIdLike("fedora", ""), DISTROS.FEDORA);
      expect(Linux.distroFromIdLike("arch", ""), DISTROS.ARCH);
      expect(Linux.distroFromIdLike("opensuse", ""), DISTROS.OPENSUSE);
    });

    test("rhel derivatives land on Fedora", () {
      expect(
          Linux.distroFromIdLike("almalinux", "rhel centos"), DISTROS.FEDORA);
    });

    test("nothing recognisable keeps the documented Debian default", () {
      expect(Linux.distroFromIdLike("", ""), DISTROS.DEBIAN);
      expect(Linux.distroFromIdLike("plan9", "inferno"), DISTROS.DEBIAN);
    });
  });

  group("enum round trips from config", () {
    test("a known distribution name reads back", () {
      expect(getEnumFromString("ZORINOS"), DISTROS.ZORINOS);
    });

    test("a stale distribution name falls back instead of throwing", () {
      // This used to be a firstWhere without orElse, which threw StateError
      // during startup and left no way to reach the setting that caused it.
      expect(getEnumFromString("SOME_REMOVED_DISTRO"), DISTROS.DEBIAN);
    });

    test("desktop reads both the plain name and the legacy toString form", () {
      expect(getDektopEnumOfString("KDE"), DESKTOPS.KDE);
      expect(getDektopEnumOfString("DESKTOPS.KDE"), DESKTOPS.KDE);
    });

    test("an unknown desktop falls back instead of throwing", () {
      expect(getDektopEnumOfString("Sway"), DESKTOPS.GNOME);
    });
  });

  group("update version comparison", () {
    setUp(() => currentLinuxAssistantVersion = "0.7.0");

    test("a higher version is offered", () {
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.8.0"), isTrue);
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("1.0.0"), isTrue);
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.7.1"), isTrue);
    });

    test("the same or an older version is not", () {
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.7.0"), isFalse);
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.6.2"), isFalse);
    });

    test("a two component tag does not throw", () {
      // "0.8" used to trip an assert and then int.parse on a missing element.
      expect(LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.8"), isTrue);
      expect(LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.7"), isFalse);
    });

    test("a pre-release suffix is read up to the number", () {
      expect(LinuxAssistantUpdater.isVersionGreaterThanCurrent("0.8.0-rc1"),
          isTrue);
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("v0.8.0"), isTrue);
    });

    test("garbage reports no update rather than throwing", () {
      expect(
          LinuxAssistantUpdater.isVersionGreaterThanCurrent("latest"), isFalse);
      expect(LinuxAssistantUpdater.isVersionGreaterThanCurrent(""), isFalse);
    });
  });

  group("hotkey modifier", () {
    setUp(() {
      Linux.currentenvironment = Environment();
      Linux.currentenvironment.desktop = DESKTOPS.GNOME;
      Linux.currentenvironment.distribution = DISTROS.FEDORA;
    });

    test("KDE uses Alt regardless of the distribution", () {
      Linux.currentenvironment.desktop = DESKTOPS.KDE;
      Linux.currentenvironment.distribution = DISTROS.FEDORA;

      expect(Linux.getHotkeyModifier(), "<Alt>");
    });

    test("distributions that bind Super themselves get Alt", () {
      // GNOME's own Super+Q / overview bindings collide, so these ship Alt.
      for (final DISTROS distro in [
        DISTROS.ZORINOS,
        DISTROS.UBUNTU,
        DISTROS.POPOS,
      ]) {
        Linux.currentenvironment.distribution = distro;
        expect(Linux.getHotkeyModifier(), "<Alt>", reason: "$distro");
      }
    });

    test("everything else gets Super", () {
      Linux.currentenvironment.distribution = DISTROS.DEBIAN;
      expect(Linux.getHotkeyModifier(), "<Super/Windows>");
    });

    test("the modifier carries no padding", () {
      // The callers interpolate it into "{modifier} + <Q>"; a trailing space
      // rendered as a double space there.
      Linux.currentenvironment.distribution = DISTROS.DEBIAN;
      expect(Linux.getHotkeyModifier().trim(), Linux.getHotkeyModifier());
    });
  });
}
