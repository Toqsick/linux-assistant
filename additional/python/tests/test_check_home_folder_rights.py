"""Tests for check_home_folder_rights — mocks jessentials.run_command."""
import sys
import os
import pytest
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from check_home_folder_rights import check_home_folder_rights

# ls -al output: index 1 is the home dir line itself (after "total NNN")
# Format: drwxr-xr-x  ...  .
# Positions [5]=group-write, [7]=other-read, [8]=other-write, [9]=other-exec

SECURE_LINE   = "drwx------  2 user user 4096 Jun 30 ."  # all others blocked
INSECURE_LINE = "drwxr-xr-x  2 user user 4096 Jun 30 ."  # world-readable

def test_secure_home_no_output(capsys):
    with patch("jessentials.run_command", return_value=["total 8", SECURE_LINE]):
        check_home_folder_rights("/home/user")
    captured = capsys.readouterr()
    assert "homefoldernotsecure" not in captured.out

def test_insecure_home_prints_warning(capsys):
    with patch("jessentials.run_command", return_value=["total 8", INSECURE_LINE]):
        check_home_folder_rights("/home/user")
    captured = capsys.readouterr()
    assert "homefoldernotsecure" in captured.out

def test_insecure_home_includes_line(capsys):
    with patch("jessentials.run_command", return_value=["total 8", INSECURE_LINE]):
        check_home_folder_rights("/home/user")
    captured = capsys.readouterr()
    assert INSECURE_LINE in captured.out
