import csv
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import check_skill_spec_coverage as coverage


class CheckSkillSpecCoverageTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.csv_path = self.root / "skills_taxonomy.csv"
        self.specs_dir = self.root / "skill_specs"
        self.specs_dir.mkdir()

    def _write_csv(self, skill_ids):
        with self.csv_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["skill_id", "domain", "construct_id", "color",
                              "title_de", "title_en", "description_de", "description_en"])
            for skill_id in skill_ids:
                writer.writerow([skill_id, "A", "c", "amber", "t", "t", "d", "d"])

    def _write_spec(self, skill_id):
        (self.specs_dir / f"{skill_id}.json").write_text(
            json.dumps({"skill_id": skill_id}), encoding="utf-8"
        )

    def _run(self):
        buffer = io.StringIO()
        with (
            mock.patch.object(coverage, "TAXONOMY_CSV", self.csv_path),
            mock.patch.object(coverage, "SPECS_DIR", self.specs_dir),
            redirect_stdout(buffer),
        ):
            code = coverage.main()
        return code, buffer.getvalue()

    def test_full_coverage_exits_zero(self):
        self._write_csv(["double_zr10", "halve_zr10"])
        self._write_spec("double_zr10")
        self._write_spec("halve_zr10")

        code, out = self._run()

        self.assertEqual(code, 0)
        self.assertIn("OK: every taxonomy skill has exactly one spec", out)

    def test_missing_spec_is_reported_and_fails(self):
        self._write_csv(["double_zr10", "halve_zr10"])
        self._write_spec("double_zr10")

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("missing (1)", out)
        self.assertIn("halve_zr10", out)

    def test_orphaned_spec_is_reported_and_fails(self):
        self._write_csv(["double_zr10"])
        self._write_spec("double_zr10")
        self._write_spec("A1.1a")

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("extra (1)", out)
        self.assertIn("A1.1a", out)

    def test_missing_taxonomy_csv_fails_loudly(self):
        self.csv_path.unlink(missing_ok=True)

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("ERROR: taxonomy CSV not found", out)

    def test_malformed_spec_json_fails_loudly(self):
        self._write_csv(["double_zr10"])
        self._write_spec("double_zr10")
        (self.specs_dir / "broken.json").write_text("{not valid json", encoding="utf-8")

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("malformed (1)", out)
        self.assertIn("broken.json", out)


if __name__ == "__main__":
    unittest.main()
