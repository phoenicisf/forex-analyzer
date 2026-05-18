from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from distill_next_context import distill, load_rules, resolve_rules_path, resolve_source_path


def evaluate(source_path: Path, rules_path: Path) -> dict:
    rules = load_rules(rules_path)
    distilled = distill(source_path, rules_path)
    runtime_text = "\n".join(
        "\n".join([section["heading"], *section["content"]])
        for section in distilled["runtime_sections"]
    )

    banned_hits: list[str] = []
    for pattern in rules.get("drop_line_patterns", []):
        matches = re.findall(pattern, runtime_text, flags=re.IGNORECASE | re.MULTILINE)
        banned_hits.extend(matches)

    metrics = distilled["metrics"]
    thresholds = rules["thresholds"]
    min_phrase_coverage = thresholds.get("min_phrase_coverage", 1.0)
    checks = [
        {
            "name": "heading_coverage",
            "passed": metrics["heading_coverage_ratio"] >= thresholds["min_heading_coverage"],
            "value": metrics["heading_coverage_ratio"],
            "expected": f">= {thresholds['min_heading_coverage']}",
            "details": distilled["coverage"]["headings_missing"],
        },
        {
            "name": "command_coverage",
            "passed": metrics["command_coverage_ratio"] >= thresholds["min_command_coverage"],
            "value": metrics["command_coverage_ratio"],
            "expected": f">= {thresholds['min_command_coverage']}",
            "details": distilled["coverage"]["commands_missing"],
        },
        {
            "name": "phrase_coverage",
            "passed": metrics["phrase_coverage_ratio"] >= min_phrase_coverage,
            "value": metrics["phrase_coverage_ratio"],
            "expected": f">= {min_phrase_coverage}",
            "details": distilled["coverage"]["phrases_missing"],
        },
        {
            "name": "compression_ratio",
            "passed": metrics["compression_ratio"] <= thresholds["max_compression_ratio"],
            "value": metrics["compression_ratio"],
            "expected": f"<= {thresholds['max_compression_ratio']}",
            "details": [],
        },
        {
            "name": "banned_marker_hits",
            "passed": len(banned_hits) <= thresholds["max_banned_marker_hits"],
            "value": len(banned_hits),
            "expected": f"<= {thresholds['max_banned_marker_hits']}",
            "details": banned_hits,
        },
    ]

    passed = all(check["passed"] for check in checks)
    return {
        "passed": passed,
        "source_path": str(source_path),
        "rules_path": str(rules_path),
        "metrics": metrics,
        "checks": checks,
        "coverage": distilled["coverage"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate distilled /next runtime context")
    parser.add_argument("--source", help="Path to next.md")
    parser.add_argument("--rules", help="Path to required-anchors.json")
    parser.add_argument(
        "--output",
        help="Optional path to save the evaluation JSON",
    )
    args = parser.parse_args()

    source_path = resolve_source_path(args.source)
    rules_path = resolve_rules_path(args.rules)
    report = evaluate(source_path, rules_path)

    if args.output:
        Path(args.output).resolve().write_text(
            json.dumps(report, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    print(json.dumps(report, indent=2, ensure_ascii=False))
    if not report["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
