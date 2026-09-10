import os

def check_home_folder_rights(home_folder):
    """Read-only check that $HOME is not writable by group or others.

    Uses os.stat on purpose: the previous implementation parsed `ls -al`,
    which word-split on homes containing spaces and crashed with an
    IndexError when ls printed nothing — exactly the crash class that used
    to take the whole security check down.
    """
    if not home_folder or not os.path.isdir(home_folder):
        return
    mode = os.stat(home_folder).st_mode
    # 0o027 = group-write (0o020) plus any permission for others (0o007).
    if mode & 0o027:
        print(f"homefoldernotsecure: {oct(mode & 0o777)}")
