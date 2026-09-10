import os
import jessentials
import jfolders
import jfiles
import apt

import apt_sources
from check_home_folder_rights import check_home_folder_rights



def get_additional_sources():
    for entry in jfolders.get_folder_entries("/etc/apt/sources.list.d"):
        if not apt_sources.is_source_file(entry):
            continue
        lines = jfiles.get_all_lines_from_file(entry)
        for uri in apt_sources.parse_source_file(entry, lines):
            print(f"additionalsource: {uri}")


def get_available_updates():
    # Reads the cache apt already has. This used to run `apt update` first, on
    # every open and every reload of a page that describes itself as read-only
    # — a network fetch and a write to /var/lib/apt the user did not ask for.
    cache = apt.Cache()
    cache.upgrade(True) # dist-upgrade
    changes = cache.get_changes()
    for pkg in changes:
        if (pkg.is_installed and pkg.marked_upgrade and pkg.candidate.version != pkg.installed.version):
           print(f"upgradeablepackage: {pkg}")

def check_server_access():
    # Check for firewall
    if (jfiles.does_file_exist("/usr/sbin/ufw")):
        lines = jessentials.run_command("/usr/sbin/iptables -L", False, True)
        ufwUserFound = False
        for line in lines:
            if "ufw-user" in line:
                ufwUserFound = True
                break
        if not ufwUserFound:
            print("firewallinactive")
    else:
        print("nofirewall")
    
    # Check for Xrdp
    lines = jessentials.run_command("/usr/bin/systemctl status xrdp", False, True)
    if (len(lines) > 1):
        print("xrdprunning")
    # Check for ssh:
    lines = jessentials.run_command("/usr/bin/systemctl status ssh", False, True)
    if (len(lines) > 1):
        print("sshrunning")
        lines = jessentials.run_command("/usr/bin/systemctl status fail2ban", False, True)
        if (len(lines) == 0):
            print("fail2bannotrunning")

if __name__ == "__main__":
    jessentials.ensure_root_privileges()
    get_additional_sources()
    get_available_updates()
    check_home_folder_rights(jessentials.get_value_from_arguments("home", ""))
    check_server_access()
    print("#!script ran successfully.")
