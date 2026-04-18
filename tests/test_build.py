import importlib.util
import pathlib
import unittest


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD_PATH = REPO_ROOT / "build.py"

spec = importlib.util.spec_from_file_location("rustdesk_build", BUILD_PATH)
build = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(build)


class BuildScriptTests(unittest.TestCase):
    def test_windows_portable_output_name_uses_portable_suffix(self):
        name = build.windows_portable_output_name("1.2.3", "HomeRemote")

        self.assertEqual(name, "HomeRemote-1.2.3-portable.exe")
        self.assertFalse(name.endswith("install.exe"))


if __name__ == "__main__":
    unittest.main()
