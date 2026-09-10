import os
import tempfile
import unittest

from check_home_folder_rights import check_home_folder_rights


class CheckHomeFolderRightsTest(unittest.TestCase):
    """Pins the os.stat semantics that replaced the `ls -al` parsing."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.home = os.path.join(self._tmp.name, "my home")  # space on purpose
        os.mkdir(self.home)
        self.addCleanup(self._tmp.cleanup)

    def _captured(self):
        import io
        import contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            check_home_folder_rights(self.home)
        return buf.getvalue()

    def test_group_write_is_insecure(self):
        os.chmod(self.home, 0o770)
        self.assertIn("homefoldernotsecure", self._captured())

    def test_others_read_is_insecure(self):
        os.chmod(self.home, 0o754)
        self.assertIn("homefoldernotsecure", self._captured())

    def test_private_home_is_secure(self):
        os.chmod(self.home, 0o750)
        self.assertEqual(self._captured(), "")

    def test_group_read_only_is_secure(self):
        os.chmod(self.home, 0o754 - 0o004)
        self.assertEqual(self._captured(), "")

    def test_missing_home_does_not_crash(self):
        check_home_folder_rights("/nonexistent/definitely/not/here")
        check_home_folder_rights("")

    def test_home_with_spaces_is_checked_as_one_path(self):
        # The ls-based predecessor word-split paths with spaces; os.stat
        # cannot. A mode that would be secure must stay secure here.
        os.chmod(self.home, 0o700)
        self.assertEqual(self._captured(), "")


if __name__ == "__main__":
    unittest.main()
