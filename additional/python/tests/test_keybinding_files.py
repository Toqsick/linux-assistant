"""Tests for the KDE and XFCE shortcut file handling.

The property under test is idempotency: running the setup twice must leave one
shortcut, not two. Both handlers appended unconditionally before.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import keybinding_files  # noqa: E402


KHOTKEYSRC = """[Data]
DataCount=2

[Data_1]
Comment=Something else
Name=other
Type=SIMPLE_ACTION_DATA

[Data_1Actions0]
CommandURL=other-app
Type=COMMAND_URL

[General]
AllowMerge=false
""".split("\n")


class KdeKhotkeysrc(unittest.TestCase):
    def test_a_shortcut_is_added_before_general(self):
        out = keybinding_files.kde_khotkeysrc(KHOTKEYSRC, "Alt+Q")

        self.assertIn("CommandURL=linux-assistant", out)
        self.assertLess(
            out.index("CommandURL=linux-assistant"),
            out.index("[General]"),
            "the block belongs above [General]",
        )
        self.assertIn("DataCount=3", out)

    def test_running_twice_leaves_one_shortcut(self):
        once = keybinding_files.kde_khotkeysrc(KHOTKEYSRC, "Alt+Q")
        twice = keybinding_files.kde_khotkeysrc(once, "Alt+Q")

        self.assertEqual(once, twice)
        self.assertEqual(twice.count("CommandURL=linux-assistant"), 1)

    def test_a_changed_key_moves_the_existing_shortcut(self):
        once = keybinding_files.kde_khotkeysrc(KHOTKEYSRC, "Alt+Q")
        moved = keybinding_files.kde_khotkeysrc(once, "Meta+Q")

        self.assertEqual(moved.count("CommandURL=linux-assistant"), 1)
        self.assertIn("Key=Meta+Q", moved)
        self.assertNotIn("Key=Alt+Q", moved)

    def test_another_apps_key_is_not_touched(self):
        source = KHOTKEYSRC[:]
        source.insert(source.index("[Data_1Actions0]"), "Key=Ctrl+Space")

        out = keybinding_files.kde_khotkeysrc(source, "Alt+Q")
        out = keybinding_files.kde_khotkeysrc(out, "Meta+Q")

        self.assertIn("Key=Ctrl+Space", out)

    def test_an_empty_file_still_gets_the_shortcut(self):
        out = keybinding_files.kde_khotkeysrc([], "Alt+Q")
        self.assertIn("CommandURL=linux-assistant", out)
        self.assertIn("Key=Alt+Q", out)


class KdeGlobalShortcuts(unittest.TestCase):
    BASE = "[khotkeys]\n_k_friendly_name=khotkeys\n\n[kwin]\nShow Desktop=Meta+D".split("\n")

    def test_the_entry_lands_in_the_khotkeys_section(self):
        out = keybinding_files.kde_kglobalshortcutsrc(self.BASE, "Alt+Q")

        entry = f"{keybinding_files.KDE_UUID}=Alt+Q,none,linux-assistant"
        self.assertIn(entry, out)
        self.assertLess(out.index(entry), out.index("[kwin]"))

    def test_running_twice_leaves_one_entry(self):
        once = keybinding_files.kde_kglobalshortcutsrc(self.BASE, "Alt+Q")
        twice = keybinding_files.kde_kglobalshortcutsrc(once, "Alt+Q")

        self.assertEqual(once, twice)
        self.assertEqual(
            sum(1 for line in twice if line.startswith(keybinding_files.KDE_UUID)), 1
        )

    def test_a_changed_key_rewrites_the_entry(self):
        once = keybinding_files.kde_kglobalshortcutsrc(self.BASE, "Alt+Q")
        moved = keybinding_files.kde_kglobalshortcutsrc(once, "Meta+Q")

        self.assertIn(f"{keybinding_files.KDE_UUID}=Meta+Q,none,linux-assistant", moved)
        self.assertEqual(
            sum(1 for line in moved if line.startswith(keybinding_files.KDE_UUID)), 1
        )

    def test_a_file_without_the_section_gets_one(self):
        out = keybinding_files.kde_kglobalshortcutsrc(["[kwin]", "Show Desktop=Meta+D"], "Alt+Q")
        self.assertIn("[khotkeys]", out)
        self.assertIn(f"{keybinding_files.KDE_UUID}=Alt+Q,none,linux-assistant", out)


class XfceProperties(unittest.TestCase):
    LISTING = """/commands/custom/<Super>q            linux-assistant
/commands/custom/<Primary><Alt>t     exo-open --launch TerminalEmulator
/commands/custom/<Alt>q              linux-assistant
/commands/custom/override            true
"""

    def test_only_our_own_bindings_are_found(self):
        self.assertEqual(
            keybinding_files.xfce_properties_of_ours(self.LISTING),
            ["/commands/custom/<Super>q", "/commands/custom/<Alt>q"],
        )

    def test_nothing_is_found_in_an_empty_listing(self):
        self.assertEqual(keybinding_files.xfce_properties_of_ours(""), [])


if __name__ == "__main__":
    unittest.main()
