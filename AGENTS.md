# AGENTS.md — `linux-assistant`

Last verified: 2026-07-19.

Deeper instructions override `~/AGENTS.md` for this subtree.

**Purpose and stack:** Flutter/Dart Linux desktop application with a C++/GTK
runner, localization, Python helpers, and `.deb`, RPM, Arch, and Flatpak
packaging.

**Key files:** `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
`l10n.yaml`, `lib/`, `linux/CMakeLists.txt`, `additional/python/`, packaging
metadata under `deb/`, `rpmbuild/`, `flatpak/`, `PKGBUILD`, and
`.github/workflows/build.yml`.

```bash
cd ~/10-Projekte/10-active/linux-assistant
flutter pub get
flutter analyze
flutter test
flutter run
flutter build linux
bash build-bundle.sh
bash build-deb.sh
bash build-rpm.sh
bash build-arch-pkg.sh
```

The packaging scripts mutate build/package work areas. CI builds and uploads
Debian and RPM artifacts but currently does not run `flutter analyze` or
`flutter test`. Version sources are inconsistent (`pubspec.yaml`, Debian/RPM,
and `PKGBUILD` differ), so inspect all of them before release work. The current
widget test is largely a template smoke test, not broad application coverage.