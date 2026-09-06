#!/usr/bin/python3
"""Privileged entry point for the read-only security report.

This exists so the polkit action for the security page can point at one exact
program. The page used to reach root through `run_script.py`, whose only check
was `assert arguments[1].count("/") == 0 and arguments[1].endswith(".py")` —
so a single password prompt authorised running *any* Python file in that
directory as root, including the command-queue runner.

No file name crosses the privilege boundary here. The caller names a family and
this script picks the checker.
"""

import os
import runpy
import sys

import jessentials

CHECKERS = {
    "debian": "check_security.py",
    "opensuse": "check_security_opensuse.py",
    "fedora": "check_security_fedora.py",
    "arch": "check_security_arch.py",
}

jessentials.ensure_root_privileges()

family = jessentials.get_value_from_arguments("family", "debian")
if family not in CHECKERS:
    jessentials.fail(
        f"Unknown distribution family '{family}'. Known: {', '.join(sorted(CHECKERS))}"
    )

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)

# The checkers read --home from argv, which is passed through unchanged.
runpy.run_path(os.path.join(here, CHECKERS[family]), run_name="__main__")
