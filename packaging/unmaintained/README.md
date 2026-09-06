# Unmaintained packaging

These build paths are kept for reference but are **not maintained in this
fork**, and nothing here is exercised by CI.

| Path | State when it was parked (2026-09-06) |
| --- | --- |
| `rpmbuild/SPECS/linux-assistant.spec`, `build-rpm.sh` | Spec last matched 0.6.2; the polkit action installs to a path that does not match the `%{_libdir}` layout the spec builds. |
| `PKGBUILD` | `pkgver=0.5.3`. |
| `flatpak/` | Manifest targets the Freedesktop 23.08 runtime, which is end of life. |

The only maintained path is the Debian package: `build-deb.sh` plus
`deb/DEBIAN/control`.

Reviving one of these means checking it against the current `additional/python`
layout and the split polkit actions in
`org.linux-assistant.operations.policy` — both changed after these files were
last touched.
