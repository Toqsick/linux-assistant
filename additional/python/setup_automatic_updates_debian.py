import subprocess

import jessentials
import jfiles
from gi.repository import Gio

jessentials.ensure_root_privileges()
if jfiles.does_file_exist("/usr/bin/mintupdate-automation"):
    jessentials.run_command("mintupdate-automation upgrade enable")
    jessentials.run_command("mintupdate-automation autoremove enable")

    # Enable flatpak and spices update: (this is now directly executed in linux-assistant itself)
    # Has to be run without root!
    # settings = Gio.Settings(schema_id="com.linuxmint.updates")
    # settings.set_boolean("auto-update-cinnamon-spices", True)
    # settings.set_boolean("auto-update-flatpaks", True)
    exit(0)


jessentials.run_command("apt install unattended-upgrades -y", environment={"DEBIAN_FRONTEND": "noninteractive"})

# The answer used to be piped in as
#   echo ... | debconf-set-selections
# through jessentials.run_command, which shlex-splits and runs without a
# shell — so "|" and "debconf-set-selections" became arguments of echo and the
# preseed was never applied. dpkg-reconfigure then ran against whatever
# debconf already held, and the app reported success either way.
answer = "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true\n"
selections = subprocess.run(
    ["/usr/bin/debconf-set-selections"],
    input=answer.encode("utf-8"),
    check=False,
)
if selections.returncode != 0:
    jessentials.fail(
        f"debconf-set-selections failed with exit code {selections.returncode}; "
        "automatic updates were not enabled."
    )

jessentials.run_command("/usr/sbin/dpkg-reconfigure -f noninteractive unattended-upgrades", environment={"DEBIAN_FRONTEND": "noninteractive"})