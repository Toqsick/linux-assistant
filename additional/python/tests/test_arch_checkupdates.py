"""Tests for arch_checkupdates — mocks all subprocess and filesystem calls."""
import sys
import os
import pytest
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import arch_checkupdates

def _make_run_command_side_effect(dbpath_line, updates):
    """Returns a side_effect function for jessentials.run_command."""
    call_count = {"n": 0}
    def side_effect(cmd, print_output=True, return_output=False, environment=None, user=None):
        call_count["n"] += 1
        if "pacman-conf" in cmd:
            return [dbpath_line]
        if "-Qu" in cmd:
            return updates
        return []
    return side_effect

@patch("os.makedirs")
@patch("os.path.exists")
@patch("os.symlink")
@patch("os.path.isfile", return_value=False)
@patch("jessentials.run_command")
def test_arch_checkupdates_returns_updates(mock_run, mock_isfile, mock_symlink, mock_exists, mock_makedirs):
    mock_exists.return_value = False
    mock_run.side_effect = _make_run_command_side_effect(
        "/var/lib/pacman/",
        ["linux 6.9.1-1 -> 6.9.3-1", "vim 9.0-1 -> 9.1-1"]
    )
    result = arch_checkupdates.arch_checkupdates()
    assert len(result) == 2
    assert "linux" in result[0]

@patch("os.makedirs")
@patch("os.path.exists")
@patch("os.symlink")
@patch("os.path.isfile", return_value=False)
@patch("jessentials.run_command")
def test_arch_checkupdates_no_updates(mock_run, mock_isfile, mock_symlink, mock_exists, mock_makedirs):
    mock_exists.return_value = False
    mock_run.side_effect = _make_run_command_side_effect("/var/lib/pacman/", [])
    result = arch_checkupdates.arch_checkupdates()
    assert result == []

@patch("os.remove")
@patch("os.makedirs")
@patch("os.path.exists")
@patch("os.symlink")
@patch("os.path.isfile", return_value=True)  # lockfile present
@patch("jessentials.run_command")
def test_arch_checkupdates_removes_lockfile(mock_run, mock_isfile, mock_symlink, mock_exists, mock_makedirs, mock_remove):
    mock_exists.return_value = False
    mock_run.side_effect = _make_run_command_side_effect("/var/lib/pacman/", [])
    arch_checkupdates.arch_checkupdates()
    mock_remove.assert_called_once()
