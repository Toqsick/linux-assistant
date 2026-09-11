import os
import jessentials
import jfolders
import jfiles
from check_home_folder_rights import check_home_folder_rights


def get_additional_sources():
    entries = jfolders.get_folder_entries("/etc/yum.repos.d/")
    for entry in entries:
        if ("fedora.repo" in entry.lower()):
            continue
        if ("fedora-updates.repo" in entry.lower()):
            continue
        if ("pycharm.repo" in entry.lower()):
            continue
        if ("fedora-cisco-openh264.repo" in entry.lower()):
            continue
        if ("fedora-updates-testing.repo" in entry.lower()):
            continue
        if ("google-chrome.repo" in entry.lower()):
            continue
        if ("rpmfusion-nonfree-nvidia-driver.repo" in entry.lower()):
            continue
        if ("rpmfusion-nonfree-steam.repo" in entry.lower()):
            continue
        lines = jfiles.get_all_lines_from_file(entry)

        name = ""
        enabled = False
        for line in lines:
            if line.startswith("[") and line.strip().endswith("]"):
                name = line.replace("[", "").replace("]", "")
            if line.startswith("name="):
                name = line.replace("name=", "")
            if ("enabled=1" in line):
                enabled = True
            if ("enabled=0" in line):
                enabled = enabled or False
        if name != "" and enabled:
            print(f"additionalsource: {name}")

def get_available_updates():
    # Read-only: --cacheonly refreshes nothing, repoquery installs nothing.
    # This used to run `dnf update` — twice — on a page whose polkit action
    # promises "Nothing is changed": with assumeyes set in dnf.conf it would
    # actually upgrade the system.
    lines = jessentials.run_command(
        "/usr/bin/dnf -q --cacheonly repoquery --upgrades", False, True,
        {'LC_ALL': 'C'})
    for _ in lines:
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
    # Check for ssh: Fedora names the unit sshd.
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
