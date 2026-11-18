#!/usr/bin/env python3
"""Offline distribution checks; these do not execute the prompt workflow."""

import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DistributionContracts(unittest.TestCase):
    def test_thirteen_named_skills_keep_invocation_tokens(self):
        skills = list((ROOT / "skills").glob("*/SKILL.md"))
        self.assertEqual(len(skills), 13)
        for path in skills:
            with self.subTest(skill=path.parent.name):
                frontmatter, body = path.read_text().split("---\n", 2)[1:]
                self.assertIn(f"name: {path.parent.name}\n", frontmatter)
                description = re.search(r"^description: (.+)$", frontmatter, re.M)
                self.assertIsNotNone(description)
                self.assertLessEqual(len(description[1]), 1024)
                self.assertIn("argument-hint:", frontmatter)
                self.assertIn("**[Required Reading]**", body)
                if path.parent.name not in {"grimoire-update"}:
                    self.assertIn("$ARGUMENTS", body)

    def test_bootstrap_and_adapter_are_release_pinned(self):
        version = (ROOT / "VERSION").read_text().strip()
        adapter = (ROOT / "AGENTES-CHAT.md").read_text()
        self.assertIn(f"Grimoire {version}", adapter)
        self.assertIn(f"`VERSION` = `{version}`", adapter)
        for path in (ROOT / "skills").glob("*/SKILL.md"):
            with self.subTest(skill=path.parent.name):
                body = path.read_text()
                bootstrap = body.split("**[Required Reading]**")[0]
                self.assertIn(f"agentes.chat, Grimoire {version}", bootstrap)
                self.assertIn(f"/v{version}/AGENTES-CHAT.md", bootstrap)
                self.assertIn("${GRIMOIRE_HOME}", bootstrap)
        self.assertIn(f"## [{version}]", (ROOT / "CHANGELOG.md").read_text())

    def test_required_convention_sections_exist(self):
        conventions = (ROOT / "GRIMOIRE-CONVENTIONS.md").read_text()
        sections = set(re.findall(r"^## § (.+)$", conventions, re.M))
        for path in (ROOT / "skills").glob("*/SKILL.md"):
            with self.subTest(skill=path.parent.name):
                for section in re.findall(r"`§ ([^`]+)`", path.read_text()):
                    self.assertIn(section, sections)

    def test_native_dispatch_reaches_all_consumers(self):
        for name in ("construct", "construct-update", "spec", "run", "execute", "init", "update", "know"):
            body = (ROOT / f"skills/grimoire-{name}/SKILL.md").read_text()
            with self.subTest(skill=name):
                self.assertIn("AGENTES-CHAT.md", body)
                self.assertNotIn("gh is not authenticated", body)
        spec = (ROOT / "skills/grimoire-spec/SKILL.md").read_text()
        mode = spec.split("**[Phase 0: Input-Mode Detection]**")[1].split("**[Phase 1:")[0]
        self.assertLess(mode.index("ac:<UUID>"), mode.index("Only digits"))
        self.assertIn("Native construct consumption", spec.split("**[Phase 5: Persist]**")[1])
        run = (ROOT / "skills/grimoire-run/SKILL.md").read_text()
        self.assertIn("Native dispatch first", run)
        self.assertIn("only for GitHub-stored constructs", run)
        update = (ROOT / "skills/grimoire-update/SKILL.md").read_text()
        self.assertLess(update.index("[Managed catalog branch"), update.index("[Phase 1:"))

    def test_default_config_preserves_existing_backend(self):
        config = tomllib.loads((ROOT / "config.example.toml").read_text())
        self.assertEqual(config["constructs"]["backend"], "auto")
        self.assertEqual(config["github"]["mode"], "auto")
        self.assertEqual(config["github"]["branch_prefix"], "grimoire")
        conventions = (ROOT / "GRIMOIRE-CONVENTIONS.md").read_text()
        schema = conventions.split("```toml\n", 1)[1].split("```", 1)[0]
        self.assertEqual(tomllib.loads(schema)["constructs"], config["constructs"])

    def test_local_markdown_document_links_exist(self):
        files = [*ROOT.glob("*.md"), *ROOT.glob("docs/*.md")]
        for path in files:
            for target in re.findall(r"\]\(([^)\s]+\.md(?:#[^)\s]*)?)\)", path.read_text()):
                if "://" in target or "<" in target:
                    continue
                with self.subTest(file=path.name, target=target):
                    self.assertTrue((path.parent / target.split("#", 1)[0]).is_file())


if __name__ == "__main__":
    unittest.main(verbosity=2)
