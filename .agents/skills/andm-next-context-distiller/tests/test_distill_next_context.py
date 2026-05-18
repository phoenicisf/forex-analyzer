from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = SKILL_ROOT / "scripts"
SOURCE_PATH = SKILL_ROOT.parents[1] / "workflows" / "next.md"
RULES_PATH = SKILL_ROOT / "references" / "required-anchors.json"

sys.path.insert(0, str(SCRIPTS_DIR))

from distill_next_context import (  # noqa: E402
    compute_phrase_coverage,
    distill,
    filter_lines,
    load_rules,
    normalize_title,
    parse_sections,
    relative_source_path,
)
from evaluate_distillation import evaluate  # noqa: E402


RULES = load_rules(RULES_PATH)


# ---------------------------------------------------------------------------
# Unit tests — core functions
# ---------------------------------------------------------------------------

class NormalizeTitleTests(unittest.TestCase):
    def test_strips_backticks(self) -> None:
        self.assertEqual(normalize_title("`/next`"), "/next")

    def test_strips_bold_asterisks(self) -> None:
        self.assertEqual(normalize_title("**Phase 0**"), "Phase 0")

    def test_normalizes_dashes(self) -> None:
        self.assertEqual(normalize_title("A — B – C"), "A - B - C")

    def test_collapses_whitespace(self) -> None:
        self.assertEqual(normalize_title("Check   0.5:  Open"), "Check 0.5: Open")


class ParseSectionsTests(unittest.TestCase):
    def test_parses_headings(self) -> None:
        text = "## Heading One\nline1\n### Heading Two\nline2\n"
        sections = parse_sections(text)
        self.assertEqual(len(sections), 2)
        self.assertEqual(sections[0].title, "Heading One")
        self.assertEqual(sections[1].title, "Heading Two")

    def test_collects_body_lines(self) -> None:
        text = "## H\nbody1\nbody2\n"
        sections = parse_sections(text)
        self.assertEqual(sections[0].lines, ["body1", "body2"])

    def test_heading_inside_code_block_not_split(self) -> None:
        text = "## Outer\n```\n## Inner Heading\ncontent\n```\nafter\n"
        sections = parse_sections(text)
        self.assertEqual(len(sections), 1)
        self.assertEqual(sections[0].title, "Outer")
        body = "\n".join(sections[0].lines)
        self.assertIn("## Inner Heading", body)

    def test_ignores_h1(self) -> None:
        text = "# Top Level\nparagraph\n## Real Section\ncontent\n"
        sections = parse_sections(text)
        self.assertEqual(len(sections), 1)
        self.assertEqual(sections[0].title, "Real Section")


class FilterLinesTests(unittest.TestCase):
    def test_keeps_list_items(self) -> None:
        lines = ["- item one", "- item two", "plain text that is noise"]
        result = filter_lines(lines, RULES)
        self.assertIn("- item one", result)
        self.assertIn("- item two", result)

    def test_drops_banned_patterns(self) -> None:
        lines = ["- good item", "review-from-gpt4 said something", "- another good"]
        result = filter_lines(lines, RULES)
        joined = "\n".join(result)
        self.assertNotIn("review-from-gpt", joined.lower())

    def test_keeps_code_blocks_with_runtime_content(self) -> None:
        lines = ["```", "Phase: Design", "Status: ไม่ครบ", "```"]
        result = filter_lines(lines, RULES)
        self.assertIn("Phase: Design", result)
        self.assertIn("Status: ไม่ครบ", result)

    def test_keeps_table_rows(self) -> None:
        lines = ["| Col A | Col B |", "|-------|-------|", "| val1  | val2  |"]
        result = filter_lines(lines, RULES)
        self.assertEqual(len(result), 3)

    def test_keeps_important_quotes(self) -> None:
        lines = ["> **Important:** do not skip this"]
        result = filter_lines(lines, RULES)
        self.assertTrue(any("do not skip this" in l for l in result))

    def test_drops_history_quotes(self) -> None:
        lines = ["> **Why this check exists:** historical reason paragraph"]
        result = filter_lines(lines, RULES)
        joined = "\n".join(result)
        self.assertNotIn("Why this check exists", joined)


class PhraseCoverageTests(unittest.TestCase):
    def test_all_phrases_found(self) -> None:
        text = "BREAKAGE OVERRIDE STOP Do first: Do NOT do yet: Confidence: Files to open before starting:"
        present, missing = compute_phrase_coverage(text, RULES)
        self.assertEqual(len(missing), 0)

    def test_missing_phrases_reported(self) -> None:
        text = "STOP Do first:"
        present, missing = compute_phrase_coverage(text, RULES)
        self.assertGreater(len(missing), 0)
        self.assertIn("BREAKAGE OVERRIDE", missing)


class RelativeSourcePathTests(unittest.TestCase):
    def test_returns_posix_relative(self) -> None:
        result = relative_source_path(SOURCE_PATH)
        self.assertNotIn("\\", result)
        self.assertIn("workflows/next.md", result)

    def test_falls_back_for_external_path(self) -> None:
        external = Path("/tmp/random/file.md")
        result = relative_source_path(external)
        self.assertIsInstance(result, str)


# ---------------------------------------------------------------------------
# Integration tests — full pipeline (existing)
# ---------------------------------------------------------------------------

class DistillNextContextTests(unittest.TestCase):
    def test_distillation_covers_runtime_headings(self) -> None:
        distilled = distill(SOURCE_PATH, RULES_PATH)
        self.assertGreaterEqual(distilled["metrics"]["heading_coverage_ratio"], 0.95)
        self.assertGreaterEqual(distilled["metrics"]["command_coverage_ratio"], 0.95)

    def test_distillation_covers_required_phrases(self) -> None:
        distilled = distill(SOURCE_PATH, RULES_PATH)
        self.assertGreaterEqual(distilled["metrics"]["phrase_coverage_ratio"], 1.0)
        self.assertEqual(len(distilled["coverage"]["phrases_missing"]), 0)

    def test_distillation_drops_known_noise(self) -> None:
        distilled = distill(SOURCE_PATH, RULES_PATH)
        rendered = "\n".join(
            "\n".join([section["heading"], *section["content"]])
            for section in distilled["runtime_sections"]
        )
        self.assertNotIn("Self-Validation Scenario Matrix", rendered)
        self.assertNotIn("review-from-gpt", rendered.lower())

    def test_compression_ratio_within_bounds(self) -> None:
        distilled = distill(SOURCE_PATH, RULES_PATH)
        ratio = distilled["metrics"]["compression_ratio"]
        self.assertLessEqual(ratio, 0.6, f"compression ratio {ratio:.2%} exceeds 60%")
        self.assertGreater(ratio, 0.0)

    def test_evaluation_report_passes(self) -> None:
        report = evaluate(SOURCE_PATH, RULES_PATH)
        self.assertTrue(report["passed"], msg=json.dumps(report, indent=2))
        check_names = [c["name"] for c in report["checks"]]
        self.assertIn("phrase_coverage", check_names)


if __name__ == "__main__":
    unittest.main()
