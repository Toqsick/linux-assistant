"""Tests for jessentials.py — pure-logic functions only (no root, no subprocess)."""
import sys
import os
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ---------------------------------------------------------------------------
# jessentials: get_value_from_arguments
# ---------------------------------------------------------------------------
import jessentials

def test_get_value_from_arguments_present(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py", "--home=/root"])
    assert jessentials.get_value_from_arguments("home", "") == "/root"

def test_get_value_from_arguments_missing(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py"])
    assert jessentials.get_value_from_arguments("home", "/default") == "/default"

def test_get_value_from_arguments_empty_value(monkeypatch):
    # --home= with nothing after the equals sign returns the default
    monkeypatch.setattr(sys, "argv", ["script.py", "--home="])
    assert jessentials.get_value_from_arguments("home", "fallback") == "fallback"

# ---------------------------------------------------------------------------
# jessentials: is_argument_option_given
# ---------------------------------------------------------------------------
def test_is_argument_option_given_long(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py", "--verbose"])
    assert jessentials.is_argument_option_given(long_code="verbose") is True

def test_is_argument_option_given_short(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py", "-v"])
    assert jessentials.is_argument_option_given(short_code="v") is True

def test_is_argument_option_given_absent(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py"])
    assert jessentials.is_argument_option_given(long_code="verbose") is False

# ---------------------------------------------------------------------------
# jessentials: remove_duplicates
# ---------------------------------------------------------------------------
def test_remove_duplicates_basic():
    assert jessentials.remove_duplicates([1, 2, 2, 3]) == [1, 2, 3]

def test_remove_duplicates_empty():
    assert jessentials.remove_duplicates([]) == []

def test_remove_duplicates_strings():
    result = jessentials.remove_duplicates(["a", "b", "a"])
    assert result == ["a", "b"]

def test_remove_duplicates_no_duplicates():
    assert jessentials.remove_duplicates([1, 2, 3]) == [1, 2, 3]

# ---------------------------------------------------------------------------
# jessentials: is_element_in_array
# ---------------------------------------------------------------------------
def test_is_element_in_array_found():
    assert jessentials.is_element_in_array(["x", "y"], "x") is True

def test_is_element_in_array_not_found():
    assert jessentials.is_element_in_array(["x", "y"], "z") is False

def test_is_element_in_array_empty():
    assert jessentials.is_element_in_array([], "x") is False

# ---------------------------------------------------------------------------
# jessentials: get_accessible_table_of_raw_csv_table
# ---------------------------------------------------------------------------
def test_get_accessible_table_basic():
    raw = [["City", "Distance"], ["Nuremberg", "35"], ["Munich", "87"]]
    result = jessentials.get_accessible_table_of_raw_csv_table(raw)
    assert result[0]["City"] == "Nuremberg"
    assert result[1]["Distance"] == "87"

def test_get_accessible_table_empty_rows():
    raw = [["Name"]]
    result = jessentials.get_accessible_table_of_raw_csv_table(raw)
    assert result == []

# ---------------------------------------------------------------------------
# jessentials: replace_tilde_to_home
# ---------------------------------------------------------------------------
def test_replace_tilde_to_home(monkeypatch):
    monkeypatch.setenv("HOME", "/home/testuser")
    assert jessentials.replace_tilde_to_home("~/docs") == "/home/testuser/docs"

def test_replace_tilde_no_tilde():
    assert jessentials.replace_tilde_to_home("/absolute/path") == "/absolute/path"

# ---------------------------------------------------------------------------
# jessentials: add_arrays
# ---------------------------------------------------------------------------
def test_add_arrays():
    assert jessentials.add_arrays([1, 2], [3, 4]) == [1, 2, 3, 4]

def test_add_arrays_empty_second():
    assert jessentials.add_arrays([1], []) == [1]

def test_add_arrays_both_empty():
    assert jessentials.add_arrays([], []) == []

# ---------------------------------------------------------------------------
# jessentials: get_environment_variable
# ---------------------------------------------------------------------------
def test_get_environment_variable_set(monkeypatch):
    monkeypatch.setenv("TEST_VAR", "hello")
    assert jessentials.get_environment_variable("TEST_VAR") == "hello"

def test_get_environment_variable_missing(monkeypatch):
    monkeypatch.delenv("TEST_VAR", raising=False)
    assert jessentials.get_environment_variable("TEST_VAR", "default") == "default"
