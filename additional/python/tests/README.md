# Python Helper Tests

Unit tests for `additional/python/` helper scripts.  
Runs with **pytest** — no root required, all subprocess calls are mocked.

## Run

```bash
# from repo root
cd additional/python
python -m pytest tests/ -v
```

## Coverage

| Script | Tests | Notes |
|---|---|---|
| `jessentials.py` | `test_jessentials.py` | Pure-logic functions: arg parsing, dedup, table builder, env vars |
| `check_home_folder_rights.py` | `test_check_home_folder_rights.py` | Mocked `ls -al` output, secure/insecure cases |
| `arch_checkupdates.py` | `test_arch_checkupdates.py` | Mocked pacman calls, lockfile removal, no-updates case |
| `get_terminal_emulator.py` | `test_get_terminal_emulator.py` | `shutil.which` priority checks |

## Scripts not covered (require live system)

- `check_security*.py` — depends on `apt`, `iptables`, `systemctl`
- `get_applications.py` — depends on `.desktop` file parsing from live `/usr/share`
- `get_bookmarks.py` — depends on live browser profile paths
- `install_nvidia_driver.py` — root + hardware dependency
- `setup_keybinding.py` — depends on live dconf/xfconf

These are candidates for integration tests in a future Docker-based CI stage.
