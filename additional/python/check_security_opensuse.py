import os
import jessentials
import jfolders
import jfiles
from check_home_folder_rights import check_home_folder_rights


def get_additional_sources():
    entries = jfolders.get_folder_entries("/etc/zypp/repos.d")
    for entry in entries:
        if ("opensuse" in entry.lower()):
            continue
        if ("repo-debug.repo" in entry.lower()):
            continue
        if ("repo-source.repo" in entry.lower()):
            continue
        lines = jfiles.get_all_lines_from_file(entry)

        name = ""
        for line in lines:
            if line.startswith("[") and line.strip().endswith("]"):
                name = line.replace("[", "").replace("]", "")
            if line.startswith("name="):
                name = line.replace("name=", "")
            if ("enabled=0" in line):
                name = ""
                break
        if name != "":
            print(f"additionalsource: {name}")

def get_available_updates():
    # Read-only: --no-refresh reads the cached metadata. A refresh here would
    # hit the network and write to zypp's caches on a page whose polkit action
    # promises "Nothing is changed". Only table data rows count, not headers
    # and separators.
    lines = jessentials.run_command(
        "/usr/bin/zypper --non-interactive --no-refresh list-updates",
        False, True, {'LC_ALL': 'C'})
    update_rows = [line for line in lines
                   if line.startswith("|") and not line.startswith("| Repository")]
    for _ in update_rows:
        print("upgradeablepackage: (to be implemented)")

def check_server_access():
    # Check for firewall
    if (jfiles.does_file_exist("/usr/bin/firewall-cmd")):
        if not jessentials.systemd_unit_is_active("firewalld"):
            print("firewallinactive")
    else:
        print("nofirewall")

    # Check for Xrdp
    if jessentials.systemd_unit_is_active("xrdp"):
        print("xrdprunning")
    # Check for ssh: openSUSE names the unit sshd.
    if jessentials.systemd_unit_is_active("sshd"):
        print("sshrunning")
        if not jessentials.systemd_unit_is_active("fail2ban"):
            print("fail2bannotrunning")

if __name__ == "__main__":
    jessentials.ensure_root_privileges()
    get_additional_sources()
    get_available_updates()
    check_home_folder_rights(jessentials.get_value_from_arguments("home", ""))
    check_server_access()
    print("#!script ran successfully.")
