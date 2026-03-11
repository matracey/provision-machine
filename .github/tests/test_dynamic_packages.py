# /// script
# requires-python = ">=3.11"
# dependencies = ["ruamel.yaml==0.18.16"]
# ///
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from ruamel.yaml import YAML


WORKFLOW = Path(__file__).parents[1] / "workflows" / "update-dynamic-packages.yml"
STEPS = YAML(typ="safe").load(WORKFLOW)["jobs"]["update-packages"]["steps"]
QUERY = next(step["run"] for step in STEPS if step.get("id") == "query")
UPDATE = next(step["run"] for step in STEPS if step.get("id") == "update")


class DynamicPackagesTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / "winget" / "modules" / "packages-common.dsc.yaml"
        self.config.parent.mkdir(parents=True)
        self.config.write_text(
            "# Keep this comment\nresources:\n"
            "  - name: Static framework\n"
            "    properties:\n      id: Microsoft.DotNet.Framework.1_1\n"
            "  - name: Old SDK\n"
            "    properties:\n      id: Microsoft.DotNet.SDK.8\n",
            encoding="utf-8",
        )
        self.output = self.root / "output.txt"
        self.environment = {**os.environ, "GITHUB_OUTPUT": str(self.output)}

    def query(self, identifiers):
        script = self.root / "query.ps1"
        script.write_text(
            "function Import-Module {}\n"
            "function Find-WinGetPackage {\n"
            + "\n".join(f"[pscustomobject]@{{Id='{value}'}}" for value in identifiers)
            + "\n}\n"
            + QUERY,
            encoding="utf-8",
        )
        return subprocess.run(
            ["pwsh", "-NoProfile", "-NonInteractive", "-File", str(script)],
            cwd=self.root, env=self.environment, capture_output=True, text=True,
        )

    def update(self, packages):
        return subprocess.run(
            [sys.executable, "-c", UPDATE],
            cwd=self.root,
            env={**self.environment, "PACKAGES_JSON": json.dumps(packages)},
            capture_output=True, text=True,
        )

    def test_query_filters_fuzzy_matches_and_sorts_numeric_majors(self):
        result = self.query([
            "Microsoft.DotNet.Framework.1_1", "Microsoft.DotNet.SDK.9",
            "Microsoft.DotNet.SDK.10", "Microsoft.DotNet.SDK.8",
            "Microsoft.DotNet.SDK.10", "Microsoft.DotNet.SDK.Preview",
            "Microsoft.VCRedist.2015+.x64", "Microsoft.VCRedist.2015+.x86",
            "Microsoft.VCRedist.2015+.x64",
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        packages = json.loads(self.output.read_text(encoding="utf-8").split("=", 1)[1])
        self.assertEqual(packages["dotnet"], ["Microsoft.DotNet.SDK.10", "Microsoft.DotNet.SDK.9"])
        self.assertEqual(packages["vcredist"], ["Microsoft.VCRedist.2015+.x64"])

    def test_query_requires_both_families(self):
        result = self.query(["Microsoft.DotNet.SDK.9", "Microsoft.DotNet.SDK.10"])
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.output.exists())

    def test_update_deduplicates_preserves_static_entries_and_is_idempotent(self):
        packages = {
            "dotnet": ["Microsoft.DotNet.SDK.10", "Microsoft.DotNet.SDK.9", "Microsoft.DotNet.SDK.10"],
            "vcredist": ["Microsoft.VCRedist.2015+.x64", "Microsoft.VCRedist.2015+.x64"],
        }
        result = self.update(packages)
        self.assertEqual(result.returncode, 0, result.stderr)
        first = self.config.read_text(encoding="utf-8")
        resources = YAML(typ="safe").load(first)["resources"]
        self.assertEqual(len(resources), 4)
        self.assertIn("# Keep this comment", first)
        self.assertEqual(resources[0]["properties"]["id"], "Microsoft.DotNet.Framework.1_1")
        self.assertTrue(all(resource["properties"]["acceptAgreements"] for resource in resources[1:]))
        self.assertEqual(self.update(packages).returncode, 0)
        self.assertEqual(self.config.read_text(encoding="utf-8"), first)

    def test_update_rejects_bad_identifiers_before_writing(self):
        original = self.config.read_bytes()
        for invalid in ("Microsoft.DotNet.Framework.1_1", "Microsoft.DotNet.SDK.Preview"):
            result = self.update({
                "dotnet": ["Microsoft.DotNet.SDK.10", invalid],
                "vcredist": ["Microsoft.VCRedist.2015+.x64"],
            })
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(self.config.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
