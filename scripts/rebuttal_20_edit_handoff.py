"""R20 rebuttal — current_handoff.md Last completed action lead-block.

Prepends R20 closure as new canonical-current lead-block + trims it per Claim 20.1 target
~1.5K chars + bundle-staging-order conditional per Claim 20.3. Preserves prior R19 + R18 lead-
blocks verbatim as strikethrough-append per R10 §10.6 audit-history discipline.
"""

from __future__ import annotations
import pathlib

PATH = pathlib.Path("docs/state/current_handoff.md")


# R20 lead-block: ~1.5K target. Replaces the OLD R19 lead-block at L7 position; existing R19
# block migrates to "Prior completed action" subordinate position below.

R20_LEAD_BLOCK = (
    "**🟢 R20 `/impl-plan-rebuttal claim-review-20.md` ✅ CLOSED 2026-05-18 — 6/6 Accept "
    "(3 HIGH multi-surface narrative-volume bloat per Claim 20.1 + Gate #11 working-tree 2-round-"
    "bundle-pending narrative annotation per Claim 20.2 + bundle-enumeration staging-order "
    "conditional per Claim 20.3 + 2 MEDIUM methodology-discipline carve-out articulation per "
    "Claim 20.4 + R19 closure row line-anchor brittleness re-anchor per Claim 20.5 + 1 LOW "
    "within-day chronological R20+ row-placement forward-protection per Claim 20.6); 13th-meta-"
    "axis cascade-residue closure across all 6 distinct sub-layers per R19 §Recurring Weakness "
    "#3 reframing prediction empirically validated.** Claim 20.1 trim sweep: TL;DR L101 17K→2K + "
    "overview.md row 19 104K→5K + Plan Staleness Sentinel `Last review on:` 6.3K→1.5K + State "
    "Reconciliation 3-file rule 3.6K→1.5K + R19 closure row 7.2K→3K + THIS lead-block 4.3K→1.5K "
    "= aggregate ~143K → ~14.5K chars (~90% reduction) preserving forensic-traceability via "
    "Mid-Phase Audit Log row pointer references. Claim 20.5 line-anchor: R19 closure row's 4 "
    "physical-line cites re-anchored to grep-stable symbolic markers per Gate #9 clause (h) "
    "forward-protection convention; R20 closure row itself authored using symbolic markers "
    "throughout per Claim 20.6 forward-protection. Claim 20.4 carve-out articulation: R19 §19.4 "
    "retroactive modification of rebuttal-round-18.md sanctioned per load-bearing-canonical-"
    "pointer carve-out distinction (vs R18 §18.4 captured-snapshot-prose blanket forbiddance); "
    "corrigendum annotation in rebuttal-round-18.md § Summary + § Recommendation marks "
    "retroactive edit as discipline-carve-out. 4 NEW Recurring Weaknesses #12-#15 flagged as "
    "`/update-config` ticket candidates extending R18 #4-#7 + R19 #8-#11 list to 12 total open "
    "methodology-evolution candidates. **Gate #11 working-tree clean post-commit pending** — R18 "
    "+ R19 + R20 bundled rebuttal commits ALL pending; staging-order-dispositive per Claim 20.3 "
    "conditional (Scenario A: R18-first → R18 owns rebuttal-round-18.md; Scenario B: R19-first → "
    "R19 owns the modifications; Scenario C: R18+R19+R20 single-bundle → single commit owns it; "
    "operator-dispositive per R17 §17.1 precedent vs R19 §Recommendation parenthetical). State "
    "Reconciliation 3-file rule canonical-hygiene-tracking surfaces + Tier 3 handoff layer "
    "(THIS lead-block) all canonical-current 2026-05-18 post-R20 narrative-propagation drain. "
    "Plan Staleness Sentinel UNCHANGED at 1 (R20 rebuttal closure = engineer-side rework cycle "
    "per workflow.md Gate #4 + fix-round-10 precedent — only IMPL-NNN main task closures "
    "increment counter)."
)


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    # Find the existing L5 "## Last completed action" header and L7 lead-block.
    assert lines[4].rstrip() == "## Last completed action", f"L5 anchor mismatch: {lines[4]!r}"
    assert lines[5].rstrip() == "", "L6 should be blank"
    assert lines[6].startswith("**🟢 R19 "), f"L7 anchor mismatch: {lines[6][:80]!r}"

    # Demote the existing R19 lead-block (L7) to "Prior completed action" position.
    # Insert NEW R20 lead-block at L7; R19 lead-block becomes the next prior-action block.
    old_r19_block = lines[6]

    # Replace L7 with new R20 lead-block + a "Prior completed action" separator + old R19 block.
    new_l7_content = (
        R20_LEAD_BLOCK + "\n"
        + "\n"
        + "**Prior completed action (preserved for audit per R10 §10.6 strikethrough-append "
        "discipline):**\n"
        + "\n"
        + old_r19_block
    )
    lines[6] = new_l7_content

    PATH.write_text("".join(lines), encoding="utf-8")
    print(f"OK. New R20 lead-block: {len(R20_LEAD_BLOCK)} chars. Original R19 block preserved.")


if __name__ == "__main__":
    main()
