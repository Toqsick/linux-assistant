"""Tests for reading /etc/apt/sources.list.d.

Written against the real shape of a Zorin OS 18 / Ubuntu 24.04 machine, where
every distribution source is deb822 and release upgrades leave .distUpgrade
and .bak files behind.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import apt_sources  # noqa: E402


class FileSelection(unittest.TestCase):
    def test_leftovers_from_a_release_upgrade_are_not_sources(self):
        for name in [
            "zorin.list.distUpgrade",
            "zorin.list.bak",
            "docker.list.distUpgrade",
            "third-party.sources.save",
            "docker.list.dpkg-dist",
            "docker.list~",
        ]:
            self.assertFalse(
                apt_sources.is_source_file(f"/etc/apt/sources.list.d/{name}"),
                f"{name} was treated as a source",
            )

    def test_the_distributions_own_sources_are_not_third_party(self):
        for name in [
            "zorin.sources",
            "zorin.list",
            "zorinos-ubuntu-stable-noble.sources",
            "zorinos-ubuntu-apps-noble.sources",
            "ubuntu.sources",
            "system.sources",
            "official-package-repositories.list",
        ]:
            self.assertFalse(
                apt_sources.is_source_file(f"/etc/apt/sources.list.d/{name}"),
                f"{name} was reported as third party",
            )

    def test_a_real_third_party_source_is_kept_in_both_formats(self):
        for name in ["docker.list", "brave-browser-release.sources"]:
            self.assertTrue(
                apt_sources.is_source_file(f"/etc/apt/sources.list.d/{name}"),
                f"{name} was skipped",
            )


class OneLineFormat(unittest.TestCase):
    def parse(self, text):
        return apt_sources.parse_one_line_format(text.strip().split("\n"))

    def test_a_plain_line(self):
        self.assertEqual(
            self.parse("deb https://download.docker.com/linux/ubuntu noble stable"),
            ["https://download.docker.com/linux/ubuntu"],
        )

    def test_options_in_brackets_are_skipped(self):
        self.assertEqual(
            self.parse(
                "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] "
                "https://download.docker.com/linux/ubuntu noble stable"
            ),
            ["https://download.docker.com/linux/ubuntu"],
        )

    def test_the_component_count_does_not_matter(self):
        # The old implementation read the URI as `sections[len - 3]`, which is
        # only the URI when there happen to be exactly two components.
        one = self.parse("deb https://example.org/repo noble main")
        four = self.parse("deb https://example.org/repo noble main restricted universe multiverse")
        self.assertEqual(one, four)

    def test_comments_sources_and_blank_lines_are_ignored(self):
        self.assertEqual(
            self.parse(
                """
# deb https://commented.example/repo noble main

deb-src https://sources.example/repo noble main
deb https://real.example/repo noble main
"""
            ),
            ["https://real.example/repo"],
        )


class Deb822Format(unittest.TestCase):
    def parse(self, text):
        return apt_sources.parse_deb822_format(text.strip("\n").split("\n"))

    def test_a_zorin_style_stanza(self):
        self.assertEqual(
            self.parse(
                """
Types: deb
URIs: https://packages.zorinos.com/stable
Suites: noble
Components: main
Signed-By: /usr/share/keyrings/zorin.gpg
"""
            ),
            ["https://packages.zorinos.com/stable"],
        )

    def test_several_stanzas_in_one_file(self):
        self.assertEqual(
            self.parse(
                """
Types: deb
URIs: https://one.example/repo
Suites: noble
Components: main

Types: deb
URIs: https://two.example/repo
Suites: noble
Components: main
"""
            ),
            ["https://one.example/repo", "https://two.example/repo"],
        )

    def test_several_uris_in_one_stanza(self):
        self.assertEqual(
            self.parse(
                """
Types: deb
URIs: https://one.example/repo https://two.example/repo
Suites: noble
"""
            ),
            ["https://one.example/repo", "https://two.example/repo"],
        )

    def test_a_disabled_stanza_is_not_a_source(self):
        self.assertEqual(
            self.parse(
                """
Enabled: no
Types: deb
URIs: https://disabled.example/repo
Suites: noble
"""
            ),
            [],
        )

    def test_a_source_only_stanza_is_not_a_binary_source(self):
        self.assertEqual(
            self.parse(
                """
Types: deb-src
URIs: https://sources.example/repo
Suites: noble
"""
            ),
            [],
        )

    def test_the_field_name_never_becomes_the_uri(self):
        # `Types: deb` splits into two tokens, so the old `sections[len - 3]`
        # indexed backwards into the line and printed garbage as a repository.
        for uri in self.parse("Types: deb\nURIs: https://x.example/r\nSuites: noble"):
            self.assertTrue(uri.startswith("http"), uri)


class Dispatch(unittest.TestCase):
    def test_the_suffix_picks_the_parser(self):
        self.assertEqual(
            apt_sources.parse_source_file(
                "/etc/apt/sources.list.d/x.sources",
                ["Types: deb", "URIs: https://x.example/r", "Suites: noble"],
            ),
            ["https://x.example/r"],
        )
        self.assertEqual(
            apt_sources.parse_source_file(
                "/etc/apt/sources.list.d/x.list",
                ["deb https://x.example/r noble main"],
            ),
            ["https://x.example/r"],
        )


class AgainstThisMachine(unittest.TestCase):
    """Read-only pass over the real directory, when there is one."""

    def test_no_leftover_file_is_reported_and_every_uri_looks_like_one(self):
        directory = "/etc/apt/sources.list.d"
        if not os.path.isdir(directory):
            self.skipTest("no apt sources directory here")

        for name in sorted(os.listdir(directory)):
            path = os.path.join(directory, name)
            if not apt_sources.is_source_file(path):
                continue
            self.assertFalse(
                name.endswith((".bak", ".distUpgrade", ".save")),
                f"{name} should have been skipped",
            )
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as handle:
                    lines = handle.read().split("\n")
            except PermissionError:
                continue
            for uri in apt_sources.parse_source_file(path, lines):
                self.assertRegex(uri, r"^[a-z+.-]+:", f"{name} yielded {uri!r}")


if __name__ == "__main__":
    unittest.main()
