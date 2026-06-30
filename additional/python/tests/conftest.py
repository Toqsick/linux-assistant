"""pytest configuration for python helper tests.

Adds the parent directory (additional/python/) to sys.path so all
helper modules can be imported without installation.
"""
import sys
import os

# Ensure additional/python/ is on the path for all test modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
