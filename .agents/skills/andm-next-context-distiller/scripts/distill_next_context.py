from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


HEADING_RE = re.compile(r"^(#{2,6})\s+(.*)$")
COMMAND_RE = re.compile(r"/[a-z][a-z0-9-]*(?:\s+--?[a-z0-9-]+|\s+[A-Z0-9<>{}/|\"'.-]+)?")


@dataclass
class Section:
    heading: str
    level: int
    title: str
    lines: list[str]


def script_root() -> Path:
    return Path(__file__).resolve().parents[1]


def load_rules(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_title(value: str) -> str:
    value = value.replace("—", "-").replace("–", "-").replace("→", "->")
    value = re.sub(r"`([^`]*)`", r"\1", value)
    value = re.sub(r"\*+", "", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def parse_sections(text: str) -> list[Section]:
    sections: list[Section] = []
    current: Section | None = None
    in_code = False
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if stripped.startswith("```"):
            in_code = not in_code
        if not in_code:
            match = HEADING_RE.match(raw_line)
            if match:
                if current is not None:
                    sections.append(current)
                heading_marks, title = match.groups()
                current = Section(
                    heading=raw_line.strip(),
                    level=len(heading_marks),
                    title=normalize_title(title),
                    lines=[],
                )
                continue
        if current is not None:
            current.lines.append(raw_line.rstrip())
    if current is not None:
        sections.append(current)
    return sections


def matches_any(value: str, patterns: Iterable[str]) -> bool:
    return any(re.search(pattern, value, flags=re.IGNORECASE) for pattern in patterns)


def is_runtime_heading(title: str, rules: dict) -> bool:
    normalized = normalize_title(title).lower()
    if normalized.startswith("1.9.") and not normalized.startswith("1.9.5"):
        return True
    if normalized.startswith("a. scan current user input"):
        return True
    if normalized.startswith("b. scan state-file memory"):
        return True
    if normalized.startswith("c. override decision"):
        return True
    return any(anchor.lower() in normalized for anchor in rules["mandatory_headings"])


def is_dropped_heading(title: str, rules: dict) -> bool:
    return matches_any(title, rules.get("drop_heading_patterns", []))


def should_keep_quote(line: str) -> bool:
    lowered = line.lower()
    signals = [
        "important",
        "critical",
        "must",
        "do not",
        "don't",
        "normal",
        "block",
        "advisory",
        "hard",
        "soft",
        "bypass",
    ]
    return any(signal in lowered for signal in signals)


def should_keep_plain_line(line: str, rules: dict) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if matches_any(stripped, rules.get("drop_line_patterns", [])):
        return False
    if stripped.startswith("**If ") or stripped.startswith("**If") or stripped.startswith("**Also"):
        return True
    if stripped.startswith("### ") or stripped.startswith("## "):
        return True
    if "breakage signal" in stripped.lower():
        return True
    if "override decision" in stripped.lower():
        return True
    if "recommended" in stripped.lower() and "action" in stripped.lower():
        return True
    if "parallel_candidates" in stripped:
        return True
    if "Priority Order" in stripped or "MANDATORY format" in stripped:
        return True
    return matches_any(stripped, rules.get("keep_line_patterns", []))


def should_keep_code_line(line: str, rules: dict | None = None) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    prefixes = (
        "Phase:",
        "Status:",
        "Next Action:",
        "Check:",
        "Read:",
        "Glob:",
        "Expected:",
        "Scan:",
        "Find:",
        "Verify",
        "Triggers",
        "Track",
        "Option",
        "Do first:",
        "Do NOT do yet:",
        "Confidence:",
        "Files to open before starting:",
    )
    normalized = stripped.lstrip("*").lstrip()
    if stripped.startswith(prefixes) or normalized.startswith(prefixes):
        return True
    if stripped.startswith(("-", "1.", "2.", "3.", "4.")):
        return True
    if "STOP" in stripped or "HALT" in stripped:
        return True
    if rules:
        for phrase in rules.get("required_phrases", []):
            if phrase in stripped:
                return True
    return "/" in stripped


def filter_lines(lines: list[str], rules: dict) -> list[str]:
    kept: list[str] = []
    in_code = False
    in_table = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("```"):
            kept.append(line)
            in_code = not in_code
            in_table = False
            continue
        if in_code:
            if should_keep_code_line(line, rules):
                kept.append(line)
            continue
        if stripped.startswith("|"):
            kept.append(line)
            in_table = True
            continue
        if in_table and not stripped:
            kept.append("")
            in_table = False
            continue
        if stripped.startswith(">"):
            if matches_any(stripped, rules.get("drop_line_patterns", [])):
                continue
            if should_keep_quote(stripped):
                kept.append(re.sub(r"^>\s?", "", stripped))
            continue
        if should_keep_plain_line(line, rules):
            kept.append(line)
    return collapse_blank_lines(kept)


def collapse_blank_lines(lines: list[str]) -> list[str]:
    collapsed: list[str] = []
    last_blank = False
    for line in lines:
        blank = not line.strip()
        if blank and last_blank:
            continue
        collapsed.append(line.rstrip())
        last_blank = blank
    while collapsed and not collapsed[0].strip():
        collapsed.pop(0)
    while collapsed and not collapsed[-1].strip():
        collapsed.pop()
    return collapsed


def collect_commands(text: str) -> list[str]:
    commands = {match.group(0).strip() for match in COMMAND_RE.finditer(text)}
    return sorted(commands)


def build_runtime_sections(sections: list[Section], rules: dict) -> list[dict]:
    distilled: list[dict] = []
    for section in sections:
        if not is_runtime_heading(section.title, rules):
            continue
        if is_dropped_heading(section.title, rules):
            continue
        filtered = filter_lines(section.lines, rules)
        if not filtered:
            continue
        distilled.append(
            {
                "heading": section.heading,
                "title": section.title,
                "level": section.level,
                "content": filtered,
            }
        )
    return distilled


def compute_heading_coverage(runtime_sections: list[dict], rules: dict) -> tuple[list[str], list[str]]:
    titles = [section["title"].lower() for section in runtime_sections]
    present: list[str] = []
    missing: list[str] = []
    for anchor in rules["mandatory_headings"]:
        anchor_normalized = normalize_title(anchor).lower()
        matched = any(anchor_normalized in title for title in titles)
        if not matched and anchor_normalized.startswith("phase 1.9"):
            matched = any(title.startswith("1.9.") for title in titles)
        if not matched and anchor_normalized.startswith("pre-check 0"):
            matched = any(
                title.startswith(("a. scan current user input", "b. scan state-file memory", "c. override decision"))
                for title in titles
            )
        if matched:
            present.append(anchor)
        else:
            missing.append(anchor)
    return present, missing


def compute_command_coverage(runtime_text: str, rules: dict) -> tuple[list[str], list[str]]:
    present: list[str] = []
    missing: list[str] = []
    for command in rules["mandatory_commands"]:
        if command in runtime_text:
            present.append(command)
        else:
            missing.append(command)
    return present, missing


def compute_phrase_coverage(runtime_text: str, rules: dict) -> tuple[list[str], list[str]]:
    present: list[str] = []
    missing: list[str] = []
    for phrase in rules.get("required_phrases", []):
        if phrase in runtime_text:
            present.append(phrase)
        else:
            missing.append(phrase)
    return present, missing


def relative_source_path(source_path: Path) -> str:
    try:
        repo_root = script_root().parents[2]
        return source_path.resolve().relative_to(repo_root).as_posix()
    except ValueError:
        return str(source_path)


def render_markdown(source_path: Path, runtime_sections: list[dict], metrics: dict) -> str:
    display_path = relative_source_path(source_path)
    lines = [
        "# Distilled /next Runtime Context",
        "",
        f"- Source: `{display_path}`",
        f"- Runtime headings: {metrics['runtime_heading_count']}",
        f"- Heading coverage: {metrics['heading_coverage_ratio']:.2%}",
        f"- Command coverage: {metrics['command_coverage_ratio']:.2%}",
        f"- Phrase coverage: {metrics['phrase_coverage_ratio']:.2%}",
        f"- Compression ratio: {metrics['compression_ratio']:.2%}",
        "",
    ]
    for section in runtime_sections:
        lines.append(section["heading"])
        lines.append("")
        lines.extend(section["content"])
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def distill(source_path: Path, rules_path: Path) -> dict:
    rules = load_rules(rules_path)
    source_text = source_path.read_text(encoding="utf-8")
    sections = parse_sections(source_text)
    runtime_sections = build_runtime_sections(sections, rules)
    runtime_text = "\n".join(
        "\n".join([section["heading"], *section["content"]]) for section in runtime_sections
    )
    commands = collect_commands(runtime_text)
    headings_present, headings_missing = compute_heading_coverage(runtime_sections, rules)
    commands_present, commands_missing = compute_command_coverage(runtime_text, rules)
    phrases_present, phrases_missing = compute_phrase_coverage(runtime_text, rules)
    required_phrases = rules.get("required_phrases", [])
    metrics = {
        "source_line_count": len(source_text.splitlines()),
        "distilled_line_count": len(runtime_text.splitlines()),
        "runtime_heading_count": len(runtime_sections),
        "heading_coverage_ratio": len(headings_present) / max(len(rules["mandatory_headings"]), 1),
        "command_coverage_ratio": len(commands_present) / max(len(rules["mandatory_commands"]), 1),
        "phrase_coverage_ratio": len(phrases_present) / max(len(required_phrases), 1),
        "compression_ratio": len(runtime_text.splitlines()) / max(len(source_text.splitlines()), 1),
    }
    return {
        "source_path": str(source_path),
        "rules_path": str(rules_path),
        "runtime_sections": runtime_sections,
        "commands": commands,
        "metrics": metrics,
        "coverage": {
            "headings_present": headings_present,
            "headings_missing": headings_missing,
            "commands_present": commands_present,
            "commands_missing": commands_missing,
            "phrases_present": phrases_present,
            "phrases_missing": phrases_missing,
        },
    }


def resolve_source_path(argument: str | None) -> Path:
    if argument:
        return Path(argument).resolve()
    return script_root().parents[1] / "workflows" / "next.md"


def resolve_rules_path(argument: str | None) -> Path:
    if argument:
        return Path(argument).resolve()
    return script_root() / "references" / "required-anchors.json"


def write_outputs(distilled: dict, output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "distilled-context.json"
    markdown_path = output_dir / "distilled-context.md"
    markdown = render_markdown(Path(distilled["source_path"]), distilled["runtime_sections"], distilled["metrics"])
    json_path.write_text(json.dumps(distilled, indent=2, ensure_ascii=False), encoding="utf-8")
    markdown_path.write_text(markdown, encoding="utf-8")
    return json_path, markdown_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Distill runtime-critical context from next.md")
    parser.add_argument("--source", help="Path to the source workflow markdown file")
    parser.add_argument("--rules", help="Path to required-anchors.json")
    parser.add_argument(
        "--output-dir",
        help="Directory for distilled artifacts",
        default=str(script_root() / "distilled"),
    )
    args = parser.parse_args()

    source_path = resolve_source_path(args.source)
    rules_path = resolve_rules_path(args.rules)
    distilled = distill(source_path, rules_path)
    json_path, markdown_path = write_outputs(distilled, Path(args.output_dir).resolve())

    print(f"Wrote JSON: {json_path}")
    print(f"Wrote Markdown: {markdown_path}")
    print(
        "Coverage:"
        f" headings={distilled['metrics']['heading_coverage_ratio']:.2%},"
        f" commands={distilled['metrics']['command_coverage_ratio']:.2%},"
        f" phrases={distilled['metrics']['phrase_coverage_ratio']:.2%},"
        f" compression={distilled['metrics']['compression_ratio']:.2%}"
    )


if __name__ == "__main__":
    main()
