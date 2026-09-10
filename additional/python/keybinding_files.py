"""Pure text transformations for the KDE and XFCE shortcut files.

Both handlers appended unconditionally. `khotkeysrc` grew another `[Data_N]`
block on every run, `kglobalshortcutsrc` another line carrying the *same*
hardcoded UUID, and XFCE's property path contains the modifier
(`/commands/custom/<Super>q`), so switching from Super to Alt left the old
binding in place next to the new one. The GNOME and Cinnamon handlers already
looked for an entry they own before adding one; these bring the other two to
the same behaviour.

Kept as line-in, line-out functions so they can be tested without a desktop
session.
"""

import re

COMMAND = "linux-assistant"

# Stable, and ours. It used to be hardcoded in the block that was appended
# every run, so repeated setups produced several shortcuts claiming the same
# identity.
KDE_UUID = "{c3daee14-f3bd-49db-bb5f-0a31a4b7fa73}"


def _section_of(lines, index):
    """Name of the [Section] the given line belongs to."""
    for i in range(index, -1, -1):
        stripped = lines[i].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            return stripped[1:-1]
    return ""


def find_kde_data_number(lines):
    """The N of an existing `[Data_N…]` block that runs our command."""
    for i, line in enumerate(lines):
        if line.strip() != f"CommandURL={COMMAND}":
            continue
        section = _section_of(lines, i)
        match = re.match(r"Data_(\d+)Actions\d+$", section)
        if match:
            return int(match.group(1))
    return None


def kde_khotkeysrc(lines, key):
    """Returns khotkeysrc lines with exactly one shortcut of ours, bound to [key]."""
    lines = list(lines)

    existing = find_kde_data_number(lines)
    if existing is not None:
        # Only the trigger can change; rewrite it in place.
        trigger_section = f"Data_{existing}Triggers0"
        for i, line in enumerate(lines):
            if line.startswith("Key=") and _section_of(lines, i) == trigger_section:
                lines[i] = f"Key={key}"
        return lines

    number = _next_kde_data_number(lines)
    block = f"""[Data_{number}]
Comment=Open {COMMAND}
Enabled=true
Name={COMMAND}
Type=SIMPLE_ACTION_DATA

[Data_{number}Actions]
ActionsCount=1

[Data_{number}Actions0]
CommandURL={COMMAND}
Type=COMMAND_URL

[Data_{number}Conditions]
Comment=
ConditionsCount=0

[Data_{number}Triggers]
Comment=Simple_action
TriggersCount=1

[Data_{number}Triggers0]
Key={key}
Type=SHORTCUT
Uuid={KDE_UUID}
"""

    out = []
    inserted = False
    for line in lines:
        if not inserted and line.strip() == "[General]":
            out.extend(block.split("\n"))
            inserted = True
        out.append(line)
    if not inserted:
        # No [General] section: append rather than drop the shortcut, which is
        # what the old loop did when the file was not shaped as expected.
        if out and out[-1].strip():
            out.append("")
        out.extend(block.split("\n"))
    return out


def _next_kde_data_number(lines):
    """Bumps DataCount and returns the number to use."""
    for i, line in enumerate(lines):
        if line.strip() == "[Data]":
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("DataCount="):
                    count = int(lines[j][len("DataCount="):].strip() or 0)
                    lines[j] = f"DataCount={count + 1}"
                    return count + 1
                if lines[j].strip().startswith("["):
                    break
    # No [Data] section yet: this is the first shortcut in the file.
    return 1


def kde_kglobalshortcutsrc(lines, key):
    """Returns lines with exactly one `[khotkeys]` entry for our UUID."""
    lines = list(lines)
    entry = f"{KDE_UUID}={key},none,{COMMAND}"

    for i, line in enumerate(lines):
        if line.startswith(f"{KDE_UUID}=") and _section_of(lines, i) == "khotkeys":
            lines[i] = entry
            return lines

    for i, line in enumerate(lines):
        if line.strip() == "[khotkeys]":
            lines.insert(i + 1, entry)
            return lines

    if lines and lines[-1].strip():
        lines.append("")
    lines.extend(["[khotkeys]", entry])
    return lines


def xfce_properties_of_ours(listing):
    """Property paths in `xfconf-query -c … -lv` output that run our command.

    The path carries the key combination, so the only way to change the
    modifier without leaving the old binding behind is to find ours by value.
    """
    paths = []
    for raw in listing.split("\n"):
        line = raw.strip()
        if not line.startswith("/commands/custom/"):
            continue
        parts = line.split()
        if len(parts) >= 2 and parts[-1] == COMMAND:
            paths.append(parts[0])
    return paths
