import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import sync_skill_specs


class SyncSkillSpecsTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.v1 = self.root / "docs" / "clean-room" / "skills" / "specs"
        self.v2 = self.root / "docs" / "clean-room" / "v2" / "skills" / "specs"
        self.v1.mkdir(parents=True)
        self.v2.mkdir(parents=True)
        self.dest = self.root / "math_app" / "assets" / "skill_specs"

    def _write(self, directory: Path, name: str, body: str) -> None:
        (directory / name).write_text(body, encoding="utf-8")

    def _run(self, source_dirs):
        buffer = io.StringIO()
        with (
            mock.patch.object(sync_skill_specs, "SRC_DIRS", source_dirs),
            mock.patch.object(sync_skill_specs, "DEST_DIR", self.dest),
            redirect_stdout(buffer),
        ):
            code = sync_skill_specs.main()
        return code, buffer.getvalue()

    def test_syncs_v1_and_v2_specs_into_the_flat_assets_dir(self):
        self._write(self.v1, "A1.1a.json", '{"skill_id": "A1.1a"}')
        self._write(
            self.v2,
            "verdoppeln-halbieren.ZR10.json",
            '{"skill_id": "verdoppeln-halbieren.ZR10"}',
        )

        code, out = self._run([self.v1, self.v2])

        self.assertEqual(code, 0)
        self.assertIn("synced 2 skill specs", out)
        self.assertIn("2 copied, 0 unchanged", out)
        self.assertEqual(
            sorted(p.name for p in self.dest.glob("*.json")),
            ["A1.1a.json", "verdoppeln-halbieren.ZR10.json"],
        )

    def test_second_run_leaves_byte_identical_files_untouched(self):
        self._write(self.v1, "A1.1a.json", '{"skill_id": "A1.1a"}')
        self._write(
            self.v2,
            "verdoppeln-halbieren.ZR10.json",
            '{"skill_id": "verdoppeln-halbieren.ZR10"}',
        )

        self._run([self.v1, self.v2])
        code, out = self._run([self.v1, self.v2])

        self.assertEqual(code, 0)
        self.assertIn("0 copied, 2 unchanged", out)

    def test_changed_source_is_recopied(self):
        self._write(self.v1, "A1.1a.json", '{"skill_id": "A1.1a"}')
        self._run([self.v1, self.v2])

        self._write(self.v1, "A1.1a.json", '{"skill_id": "A1.1a", "v": 2}')
        code, out = self._run([self.v1, self.v2])

        self.assertEqual(code, 0)
        self.assertIn("1 copied, 0 unchanged", out)
        self.assertEqual(
            (self.dest / "A1.1a.json").read_text(encoding="utf-8"),
            '{"skill_id": "A1.1a", "v": 2}',
        )

    def test_src_dirs_includes_the_v4_specs_directory(self):
        suffixes = [d.as_posix() for d in sync_skill_specs.SRC_DIRS]
        self.assertTrue(
            any(s.endswith("docs/clean-room/v4/skills/specs") for s in suffixes),
            f"SRC_DIRS does not include the v4 specs directory: {suffixes}",
        )

    def test_missing_source_directory_fails_loudly(self):
        code, out = self._run([self.v1 / "nope", self.v2])

        self.assertEqual(code, 1)
        self.assertIn("ERROR: specs directory not found", out)
        self.assertFalse(self.dest.exists() and any(self.dest.iterdir()))


if __name__ == "__main__":
    unittest.main()
