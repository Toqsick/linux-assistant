#!/usr/bin/python3
"""Runs the queue Linux Assistant wrote, as root.

Reads a JSON-Lines file, one command per line:

    {"uid": 0, "argv": ["/usr/bin/apt", "install", "vlc", "-y"],
     "env": {"DEBIAN_FRONTEND": "noninteractive"}, "shell": false}

Each command is executed **without a shell**. The previous version received a
single command string per line and ran it as `bash -c "<string>"`, so every
value the app interpolated into that string — a Timeshift snapshot name read
off a mounted disk, a mountpoint, a package name from a search result — was
shell source code with root privileges. The old line format also lost data: it
was split on `";"` and on `=`, so a value containing either arrived mangled.

The parsing and execution live in `command_queue.py` so they can be tested
without root.
"""

import hashlib
import json

import command_queue
import jessentials
import jfiles

FILE_PATH = jessentials.get_value_from_arguments("path", "")

jessentials.ensure_root_privileges()

if not jfiles.does_file_exist(FILE_PATH):
    jessentials.fail(
        f"File '{FILE_PATH}' not found. Please provide the file path via --path. Exiting.."
    )

md5_checksum_from_executor = jessentials.get_value_from_arguments("md5", "")

with open(FILE_PATH, "r", encoding="utf-8") as handle:
    string = handle.read()

actual_md5_checksum = hashlib.md5(string.encode("utf-8")).hexdigest()

# Not an authorization check. The path and the hash both arrive as argv from
# the unprivileged caller, so anything able to supply one supplies the other.
# It catches a truncated or half-written queue file, nothing more.
if md5_checksum_from_executor != actual_md5_checksum:
    jessentials.fail(f"Checksum test failed! Did anyone corrupt '{FILE_PATH}'?")

failures = 0
for number, line in enumerate(string.strip().split("\n"), start=1):
    if not line.strip():
        continue

    try:
        entry = json.loads(line)
    except json.JSONDecodeError as error:
        jessentials.fail(f"Line {number} is not valid JSON: {error}")

    try:
        uid, argv, env, use_shell = command_queue.parse_command(entry, number)
    except command_queue.QueueFormatError as error:
        jessentials.fail(str(error))

    print(f"-- COMMAND: {argv} ".ljust(96, "-"))
    try:
        exit_code = command_queue.run_command(uid, argv, env, use_shell)
    except OSError as error:
        print(f"-- FAILED to start: {error}")
        failures += 1
        continue

    if exit_code != 0:
        # Reported rather than raised: the queue is a batch, and stopping at
        # the first failing package would leave the rest of it unapplied.
        print(f"-- EXIT CODE {exit_code}")
        failures += 1

if failures:
    print(f" FINISHED WITH {failures} FAILED COMMAND(S) ".center(96, "-"))
else:
    print(" FINISHED ".center(96, "-"))
