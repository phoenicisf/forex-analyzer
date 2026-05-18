"""R20 §20.5 + §20.6 forward-protection — strip physical-line cites from R20-authored narrative.

Surgical replacements only on the NEW narrative lines (R20 closure row at L2267 + State Reconciliation
3-file rule line at L2370 which R20 §20.1 trim rewrote). Pre-existing R18/R19/R16 audit-history lines
preserved verbatim per R10 §10.6 captured-snapshot prose discipline + R20 §20.4 Methodology Discipline
Carve-out (captured-snapshot prose with no canonical-pointer status → DO NOT retroactively modify).
"""

from __future__ import annotations
import pathlib

PATH = pathlib.Path("docs/state/impl-plan.md")

# Substring substitutions on R20-authored lines only.
# Each tuple = (original substring, symbolic-anchor replacement).

R20_ROW_FIXES = [
    ("TL;DR `Last updated:` lead clause trim from ~17K chars",
     "TL;DR `Last updated:` lead clause trim from ~17K chars"),  # unchanged — no L# in source phrase
    ("worst regressors TL;DR L101 + overview.md row 19 reduced 88% + 95% respectively",
     "worst regressors TL;DR `Last updated:` lead clause + overview.md row 19 (Status column) "
     "reduced 88% + 95% respectively"),
    ("L2264↔L2265 R17↔R18 swap, L2367 Phase 5 mechanical gates, L2264-pre-swap, L2265 R18 row",
     "R17↔R18 closure row swap (within Mid-Phase Audit Log), Closure Hygiene Status "
     "`Phase 5 mechanical gates:` line, R18 closure row Files-touched column"),
    ("R19 closure row narrative trim from ~7.2K chars → ~3K chars + 4 physical-line cites",
     "R19 closure row narrative trim from ~7.2K chars → ~3K chars + 4 physical-line cites"),  # ok
]

STATE_RECON_FIXES = [
    ("R20 trim cycle reduced TL;DR L101 17K→2K chars + Sentinel L2356 6.3K→1.5K chars + "
     "State Reconciliation L2369 [this line] 3.6K→1.5K chars + R19 closure row L2266 7.2K→3K chars "
     "per Claim 20.1",
     "R20 trim cycle reduced TL;DR `Last updated:` lead clause 17K→2K chars + Plan Staleness "
     "Sentinel `Last review on:` line 6.3K→1.5K chars + Closure Hygiene Status "
     "`State Reconciliation 3-file rule:` line [this line] 3.6K→1.5K chars + R19 closure row "
     "(in Mid-Phase Audit Log) 7.2K→3K chars per Claim 20.1"),
]


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    # R20 closure row at index 2266 (file L2267).
    r20_row = lines[2266]
    assert r20_row.startswith("| 2026-05-18 | — | **R20"), "R20 row anchor mismatch"
    for old, new in R20_ROW_FIXES:
        if old in r20_row:
            r20_row = r20_row.replace(old, new, 1)
    lines[2266] = r20_row

    # State Reconciliation 3-file rule at index 2369 (file L2370).
    state_recon = lines[2369]
    assert state_recon.startswith("- **State Reconciliation 3-file rule"), (
        "State Reconciliation anchor mismatch"
    )
    for old, new in STATE_RECON_FIXES:
        if old in state_recon:
            state_recon = state_recon.replace(old, new, 1)
    lines[2369] = state_recon

    PATH.write_text("".join(lines), encoding="utf-8")
    print("OK. R20-authored physical-line cites replaced with symbolic anchors.")


if __name__ == "__main__":
    main()
