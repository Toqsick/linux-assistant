"""Reading /etc/apt/sources.list.d.

The security page lists the third-party repositories a system has picked up.
The previous implementation understood only the one-line `deb …` syntax and
picked the URI as `sections[len - 3]`, which assumed exactly two components.
On Ubuntu 24.04 and everything built on it — Zorin OS 18 included — the files
are deb822 (`Types:` / `URIs:` / `Suites:`), where that index is negative and
the "repository" it reported was a fragment of a field name.

It also read every file in the directory, so each `zorin.list.distUpgrade` and
`zorin.list.bak` left behind by a release upgrade was reported as an unknown
third-party source.
"""

import os

# Only these are apt sources. Everything else in that directory is a leftover:
# .distUpgrade and .save from release upgrades, .bak from edits, .dpkg-dist
# and .ucf-* from package upgrades.
SOURCE_SUFFIXES = (".list", ".sources")

# Repositories the distribution ships itself. Matched against the file name.
DISTRIBUTION_SOURCES = (
    "official-package-repositories.list",  # Linux Mint
    "debian.list",  # MX Linux
    "debian-stable-updates.list",  # MX Linux
    "mx.list",  # MX Linux
    "zorin.list",  # Zorin OS
    "zorin.sources",  # Zorin OS 18
    "zorinos-ubuntu-",  # Zorin OS PPAs
    "system.sources",  # Pop!_OS
    "neon.list",  # KDE neon
    "org.kde.neon.net.launchpad.ppa.mozillateam.list",  # KDE neon
    "preinstalled-pool.list",  # KDE neon
    "ubuntu.sources",  # Ubuntu
    "ubuntu-esm-apps.sources",  # Ubuntu ESM
    "ubuntu-esm-infra.sources",  # Ubuntu ESM
)


def is_source_file(path):
    name = os.path.basename(path)
    if not name.endswith(SOURCE_SUFFIXES):
        return False
    return not any(known in name for known in DISTRIBUTION_SOURCES)


def parse_one_line_format(lines):
    """URIs from the classic `deb [options] URI SUITE COMPONENTS…` syntax."""
    uris = []
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("deb-src"):
            continue
        if not line.startswith("deb"):
            continue

        tokens = line.split()[1:]  # drop "deb"

        # An optional bracketed option group may contain spaces:
        # deb [arch=amd64 signed-by=/usr/share/keyrings/x.gpg] https://… stable main
        if tokens and tokens[0].startswith("["):
            while tokens and not tokens[0].endswith("]"):
                tokens.pop(0)
            if tokens:
                tokens.pop(0)

        if tokens:
            uris.append(tokens[0])
    return uris


def parse_deb822_format(lines):
    """URIs from the deb822 stanza syntax, honouring `Enabled: no`."""
    uris = []
    stanza = {}

    def flush():
        if not stanza:
            return
        if stanza.get("enabled", "yes").strip().lower() in ("no", "false"):
            return
        if "deb" not in stanza.get("types", "deb").split():
            return
        uris.extend(stanza.get("uris", "").split())

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            flush()
            stanza = {}
            continue
        if line.startswith("#"):
            continue
        if line.startswith((" ", "\t")):
            continue  # continuation of the previous field; not a URI
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        stanza[key.strip().lower()] = value.strip()

    flush()
    return uris


def parse_source_file(path, lines):
    if path.endswith(".sources"):
        return parse_deb822_format(lines)
    return parse_one_line_format(lines)
