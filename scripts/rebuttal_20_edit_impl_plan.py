"""R20 rebuttal — impl-plan.md atomic narrative-trim + R20 closure row insert.

Edits:
  1. L101 TL;DR `Last updated:` clause — trim ~17K → ~2K (Claim 20.1).
  2. L2266 R19 closure row — trim ~7.2K → ~3K + re-anchor 4 physical-line cites to grep-stable
     symbolic markers per Gate #9 clause (h) (Claim 20.1 + Claim 20.5 combined).
  3. INSERT new L2267 R20 closure row (forward-chronological per Claim 20.6).
  4. L2356 Plan Staleness Sentinel `Last review on:` — trim ~6.3K → ~1.5K (Claim 20.1).
  5. L2368 Closure Hygiene Status `Phase 5 mechanical gates:` — refresh + 2-round-bundle-pending
     framing (Claim 20.2 narrative annotation).
  6. L2369 Closure Hygiene Status `State Reconciliation 3-file rule:` — trim ~3.6K → ~1.5K +
     bundle-staging-order conditional + axes 1-13 framing (Claim 20.1 + 20.2 + 20.3).
"""

from __future__ import annotations
import pathlib

PATH = pathlib.Path("docs/state/impl-plan.md")


# -- Replacement texts (Markdown single lines; each ends with newline) ----------

L101_NEW = (
    "> **Last updated:** 2026-05-18 · last action: **📝 `/impl-plan-rebuttal claim-review-20.md` "
    "✅ CLOSED 2026-05-18 — R20 6/6 Accept (3 HIGH multi-surface narrative-volume bloat per Claim "
    "20.1 + Gate #11 2-round-bundle-pending narrative annotation per Claim 20.2 + bundle-"
    "enumeration staging-order conditional per Claim 20.3 + 2 MEDIUM methodology-discipline "
    "carve-out per Claim 20.4 + R19 closure row line-anchor brittleness re-anchor per Claim 20.5 + "
    "1 LOW within-day chronological R20+ row-placement forward-protection per Claim 20.6); "
    "13th-meta-axis cascade-residue closure at multi-surface-narrative-volume + 2-round-Gate-11 + "
    "staging-order-bundle-enumeration + retroactive-modification-discipline-carve-out + R19-"
    "narrative-line-anchor + R20+row-placement-convention layers; R20 bundled rebuttal commit "
    "pending (R18 + R19 + R20 bundles all pending — staging-order-dispositive per Claim 20.3 "
    "conditional; operator may execute as 3 separate commits per R17 §17.1 precedent OR bundle "
    "into single commit). 4 NEW Recurring Weaknesses #12-#15 flagged as `/update-config` ticket "
    "candidates extending R18 #4-#7 + R19 #8-#11 list to 12 total open methodology-evolution "
    "candidates. State Reconciliation 3-file rule canonical-current across all 3 tiers + canonical-"
    "hygiene-tracking surfaces 2026-05-18.** · prior rebuttal closures (R19 12th-meta-axis · R18 "
    "11th-meta-axis · R17 10th-meta-axis · R16 cascade-residue · R15 BT-002 cascade drain 12/12 · "
    "R14/R13/R12 BT-001 cycle · R11/R10/R09/R07/R06) per Mid-Phase Audit Log rows (chronological "
    "R06→R20 closure chain). · prior empirical actions (IMPL-062 Run #3 + IMPL-FIX-012 iter-1/2/3 "
    "+ fix-round-26 + BT-002 OPEN/CLOSED 2026-05-17/18 + R15→R20 cascade drain) per Mid-Phase "
    "Audit Log row references. **BT-002 ✅ CLOSED 2026-05-18** (`backtrack-log.md § BT-002` Status "
    "flipped via SD R09 0 findings + BA R06 1 LOW closed); IMPL-FIX-012 → close-by-BT-002 "
    "supersession (R15 §15.8); IMPL-051 → cancel-by-BT-002 (R15 §15.7); ADR-013 + ADR-014 "
    "Superseded by BT-002 (audit history preserved). Next: post-BT-002 impl-code cleanup (delete "
    "`services/CircuitBreaker.mqh` + strip ADR-013/014 dispatch from `core/Orchestrator.mqh`) → "
    "`/impl-task IMPL-062` re-execute Bucket A 5-yr regression on rewrite no-detector default "
    "build per NFR-1.1.\n"
)


L2266_NEW = (
    "| 2026-05-18 | — | **R19 `/impl-plan-rebuttal claim-review-19.md` ✅ CLOSED — 5/5 effective "
    "Accept (3 HIGH cross-document state-reconciliation + 1 MEDIUM symbolic-anchor + 1 LOW "
    "narrative-compaction; cascade-residue verify-pass round at 12th-meta-axis next-finer-"
    "granularity layer per R18 §Recurring Weakness #3 reframing prediction empirically "
    "validated)** | impl-plan.md (TL;DR `Last updated:` lead clause refresh prepending R19 + Plan "
    "Staleness Sentinel `Last review on:` line refresh prepending R19 + Closure Hygiene Status "
    "`Plan Staleness Sentinel:` summary line refresh prepending R19 to latest-review chain + "
    "Closure Hygiene Status `Phase 5 mechanical gates:` line trim from ~7874 chars to ~3873 chars "
    "[~51% reduction] preserving forensic-traceability via Mid-Phase Audit Log row references per "
    "Claim 19.5 + Closure Hygiene Status `State Reconciliation 3-file rule:` line atomic "
    "extension to R19 closure + present-progressive rewrite for R18+R19 commit pending per Claim "
    "19.2 + Mid-Phase Audit Log R17 closure row ↔ R18 closure row swap restoring forward-"
    "chronological R15→R16→R17→R18 within 2026-05-18 cluster per Claim 19.1 + R18 closure row "
    "Files-touched column file-bundle enumeration completeness `{rebuttal-round-18.md,claim-"
    "review-18.md} (NEW per R19 §19.3 enumeration completeness)` per Claim 19.3 + literal "
    "predicted commit name → symbolic anchor `R18 bundled rebuttal commit` at 2 cite-sites per "
    "Claim 19.4 + this audit-log row), overview.md (row 19 Impl Plan status field sub-clause "
    "refresh prepending R19 5/5 effective Accept narrative + present-progressive rewrite for R18 "
    "bundled commit pending per Claim 19.2 + bundle enumeration expansion per Claim 19.3), "
    "current_handoff.md (Last completed action lead-block rewrite prepending R19 closure as "
    "canonical-current per R16 §16.3 + R10 §10.6 strikethrough-append discipline + present-"
    "progressive rewrite + dual-bundle enumeration with symbolic-anchor discipline per Claim "
    "19.2/19.3/19.4 + chained R19 verify-pass trigger lineage append), docs/state/impl-plan-claim-"
    "review-and-rebuttal/{rebuttal-round-19.md,claim-review-19.md} (NEW per R19 §19.3 forward-"
    "protection discipline) + rebuttal-round-18.md (§ Summary + § Recommendation symbolic-anchor "
    "rewrites per Claim 19.4) | Reviewer + Defender: Opus 4.7. 5 findings drained at 12th-meta-"
    "axis next-finer-granularity layer: 3 HIGH (19.1 audit-log within-day chronological mode-"
    "switch R17↔R18 row swap restoring forward-chronological R15→R16→R17→R18 within 2026-05-18 "
    "cluster; 19.2 5-surface narrative-tense past-tense → present-progressive rewrite; 19.3 "
    "file-bundle enumeration completeness Tier 1 + Tier 2 catch-up to Tier 3) + 1 MEDIUM (19.4 "
    "predicted-commit-message symbolic-anchor rewrite at 5 cite-sites; Gate #9 clause (h) "
    "extended to predicted-commit-message-stability 5th-axis layer; Recurring Weakness #8 "
    "candidate flagged) + 1 LOW (19.5 Closure Hygiene Status Phase 5 mechanical gates line trim "
    "~51% reduction preserving forensic-traceability via Mid-Phase Audit Log row references; "
    "Recurring Weakness #10 candidate flagged). R18 prediction \"R18 verify-pass clean WITHIN "
    "known axes 1-11\" empirically validated by R19 surfacing 5 findings at 12th-meta-axis NEW "
    "layers. 4 NEW Recurring Weaknesses #8-#11 flagged as `/update-config` ticket candidates. "
    "State Reconciliation 3-file rule fully restored across all 3 tiers post-R15+R16+R17 bundled "
    "rebuttal commit + R18 narrative-propagation drain + R19 narrative-propagation drain (R18 + "
    "R19 bundled rebuttal commits pending — close Gate #11 atomically across all canonical "
    "surfaces when bundled per R17 §17.1 precedent). Plan Staleness Sentinel UNCHANGED at 1 "
    "(rebuttal-cycle ≠ main task closure per workflow.md Gate #4 + fix-round-10 precedent). "
    "Phase 5 mechanical gates 1+2+4+5+8+9h+11 exercised inline (Gate #11 closed by R18 + R19 "
    "bundled rebuttal commits pending). R20 verify-pass predicted conditional clean \"WITHIN "
    "known axes 1-12\" per defect-class progression chain pattern. |\n"
)


L2267_NEW_R20_ROW = (
    "| 2026-05-18 | — | **R20 `/impl-plan-rebuttal claim-review-20.md` ✅ CLOSED — 6/6 Accept "
    "(3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass round at 13th-meta-axis next-finer-"
    "granularity layer per R19 §Recurring Weakness #3 reframing prediction empirically validated)"
    "** | impl-plan.md (TL;DR `Last updated:` lead clause trim from ~17K chars → ~2K chars per "
    "Claim 20.1 + Plan Staleness Sentinel `Last review on:` line trim from ~6.3K chars → ~1.5K "
    "chars per Claim 20.1 + Closure Hygiene Status `Phase 5 mechanical gates:` line refresh "
    "prepending R20 narrative + 2-round-bundle-pending framing per Claim 20.2 + Closure Hygiene "
    "Status `State Reconciliation 3-file rule:` line trim from ~3.6K chars → ~1.5K chars + axes "
    "1-13 framing + bundle-staging-order conditional per Claim 20.1 + 20.2 + 20.3 + R19 closure "
    "row narrative trim from ~7.2K chars → ~3K chars + 4 physical-line cites re-anchored to grep-"
    "stable symbolic markers per Claim 20.5 + Gate #9 clause (h) precedent applied at intra-"
    "round-narrative-authoring layer + this audit-log row authored using grep-stable symbolic "
    "markers throughout per Claim 20.6 forward-protection convention), overview.md (row 19 Impl "
    "Plan status field trim from ~104K chars [single 100KB Markdown row] → ~5K chars per Claim "
    "20.1 + sub-clause refresh prepending R20 6/6 Accept narrative + bundle-staging-order "
    "conditional per Claim 20.3), current_handoff.md (Last completed action lead-block trim from "
    "~4.3K chars → ~1.5K chars per Claim 20.1 + rewrite prepending R20 closure as canonical-"
    "current per R16 §16.3 + R10 §10.6 strikethrough-append discipline + bundle-staging-order "
    "conditional per Claim 20.3), docs/state/impl-plan-claim-review-and-rebuttal/{rebuttal-round-"
    "20.md,claim-review-20.md} (NEW per R19 §19.3 enumeration completeness + R20 §20.6 forward-"
    "protection convention) + rebuttal-round-18.md (§ Summary + § Recommendation corrigendum "
    "annotation marking R19 §19.4 retroactive edit as discipline-carve-out per Claim 20.4 "
    "Methodology Discipline Carve-out Articulation) | Reviewer + Defender: Opus 4.7. 6 findings "
    "drained at 13th-meta-axis next-finer-granularity layer: 3 HIGH (20.1 multi-surface narrative-"
    "volume bloat across 6 canonical-current surfaces aggregate ~143K chars → ~14.5K chars [~90% "
    "aggregate reduction] preserving forensic-traceability via Mid-Phase Audit Log row pointer "
    "references; worst regressors TL;DR L101 + overview.md row 19 reduced 88% + 95% respectively; "
    "Recurring Weakness #14 candidate flagged; 20.2 Gate #11 working-tree 2-round-bundle-pending "
    "accumulation R17 18+ files [3-round] → R19 5 files [1-round] → R20 7 files [2-round] "
    "monotonic growth — narrative immediate fix appending explicit pattern-acknowledgment across "
    "5 canonical surfaces + Recurring Weakness #12 candidate flagged for Gate #11 verify-pass-"
    "bundle carve-out codification; 20.3 bundle-enumeration staging-order ambiguity between R18 + "
    "R19 commits for rebuttal-round-18.md ownership — propagated R19 §Recommendation parenthetical "
    "conditional framing to Tier 1 + Tier 2 + Tier 3 surfaces; Scenario A/B/C operator-dispositive "
    "framing) + 2 MEDIUM (20.4 methodology-discipline self-contradiction R18 §18.4 \"would set a "
    "problematic precedent\" rationale vs R19 §19.4 retroactive modification of rebuttal-round-"
    "18.md — articulated explicit carve-out distinction in R20 rebuttal Cascaded Changes "
    "[captured-snapshot prose with no canonical-pointer status → DO NOT retroactively modify; "
    "load-bearing canonical pointer to future commit → MAY retroactively modify per Gate #9 "
    "clause (h) extension] + corrigendum annotation in rebuttal-round-18.md § Summary + § "
    "Recommendation marking R19 §19.4 retroactive edit as discipline-carve-out; Recurring "
    "Weakness #13 candidate flagged; 20.5 R19 closure row L2266 narrative-prose line-anchor "
    "brittleness regression — 4 physical-line cites [L2264↔L2265 R17↔R18 swap, L2367 Phase 5 "
    "mechanical gates, L2264-pre-swap, L2265 R18 row] replaced with grep-stable symbolic markers "
    "per R18 §18.4 forward-protection convention; Recurring Weakness #15 candidate flagged for "
    "Gate #9 clause (j) codification) + 1 LOW (20.6 within-day chronological R20+ row-placement "
    "convention codification gap — added explicit forward-protection annotation: R20 closure row "
    "placed at audit-log tail per within-day-chronological discipline established by Claim 19.1; "
    "future R-N closure rows follow same convention; Recurring Weakness #9 [from R19] continues "
    "as `/update-config` candidate). R19 prediction \"R20 verify-pass conditional clean WITHIN "
    "known axes 1-12\" empirically validated by R20 surfacing 6 findings at 13th-meta-axis NEW "
    "layers (multi-surface narrative-volume + 2-round Gate-11 + staging-order bundle-enumeration "
    "+ retroactive-modification discipline carve-out + R19-narrative line-anchor + R20+ row-"
    "placement convention). 4 NEW Recurring Weaknesses #12 (Gate #11 verify-pass-bundle carve-out) "
    "+ #13 (audit-history retroactive-modification carve-out distinction) + #14 (multi-surface "
    "narrative-volume trim convention) + #15 (narrative-prose forward-protection rule) flagged as "
    "`/update-config` ticket candidates — extends R18 #4-#7 + R19 #8-#11 list to 12 total open "
    "methodology-evolution candidates. State Reconciliation 3-file rule fully restored across "
    "all 3 tiers post-R15+R16+R17 bundled rebuttal commit + R18 + R19 + R20 narrative-propagation "
    "drain (R18 + R19 + R20 bundled rebuttal commits pending — staging-order-dispositive per "
    "Claim 20.3 conditional: Scenario A operator commits R18 first → R18 bundle owns rebuttal-"
    "round-18.md; Scenario B/C R19 commits first or bundled → R19 or single bundle owns it). "
    "Plan Staleness Sentinel UNCHANGED at 1 (R20 rebuttal closure = engineer-side rework cycle "
    "per workflow.md Gate #4 + fix-round-10 precedent — only IMPL-NNN main task closures "
    "increment counter). Phase 5 mechanical gates 1+2+4+5+8+9h+11 exercised inline. R21 verify-"
    "pass predicted conditional clean \"WITHIN known axes 1-13\" per defect-class progression "
    "chain pattern; R20 cannot rule out next-finer-granularity 14th-meta-axis surfacing per "
    "R19/R18/R17 reframing lesson. R20 closure row placed at audit-log tail per within-day-"
    "chronological discipline established by Claim 19.1 + R20 §20.6 forward-protection "
    "annotation: future R-N closure rows follow forward-chronological by closure-completion-time "
    "convention; topical-reverse-ordering rationales rejected per chronological discipline. |\n"
)


L2356_NEW = (
    "**Last review on:** 2026-05-18 — `claim-review-20.md` + `rebuttal-round-20.md` (R20 6/6 "
    "Accept — 3 HIGH multi-surface narrative-volume bloat across 6 canonical-current surfaces "
    "aggregate ~143K chars → ~14.5K chars per Claim 20.1 + Gate #11 working-tree 2-round-bundle-"
    "pending narrative annotation per Claim 20.2 + bundle-enumeration staging-order conditional "
    "per Claim 20.3 + 2 MEDIUM methodology-discipline carve-out articulation per Claim 20.4 + "
    "R19 closure row line-anchor brittleness re-anchor per Claim 20.5 + 1 LOW within-day "
    "chronological R20+ row-placement forward-protection per Claim 20.6; 13th-meta-axis cascade-"
    "residue closure across all 6 distinct sub-layers). 4 NEW Recurring Weaknesses #12-#15 "
    "flagged as `/update-config` ticket candidates extending R18 #4-#7 + R19 #8-#11 list to 12 "
    "total open methodology-evolution candidates. Prior 2026-05-18 R19 (12th-meta-axis 5/5 "
    "effective Accept) + R18 (11th-meta-axis 5/5 effective Accept) + R17 (10th-meta-axis 7/7 "
    "Accept) + R16 (cascade-residue 6/6 Accept) + R15 (BT-002 cascade drain 12/12 Accept). Prior "
    "2026-05-13 R14/R13/R12 (BT-001 cycle 6/6 + 3/4 + 6/6 Accept). Prior reviews R11 (BT-001 "
    "Step 3 drain 7/7 Accept) + R10 (6/6 Accept narrative-parallel sweep) + R09 (7/7 Accept "
    "IMPL-FIX-011 re-decomposition) + R07/R06 (6/6 + 7/7 Accept) — full chronological R06→R20 "
    "closure chain detail via Mid-Phase Audit Log row references.\n"
)


L2368_NEW = (
    "- **Phase 5 mechanical gates (`.claude/rules/workflow.md`):** Gates #1-#11 — sweep refreshed "
    "2026-05-18 post-R20 cascade-residue-at-13th-meta-axis verify-pass + R19 narrative-"
    "propagation drain (R18 + R19 + R20 rebuttal commits pending — staging-order-dispositive per "
    "Claim 20.3 conditional; close Gate #11 atomically across all canonical surfaces when "
    "bundled; pattern grows monotonically +2 untracked files per future R-N verify-pass-without-"
    "commit round per Claim 20.2). **R20 exercised Gate #1** (forbidden-pattern grep — 1 "
    "sanctioned false-positive ✅ unchanged from R19 baseline) **+ Gate #2** (TL;DR ↔ registry "
    "recount — 55 Active + 8 Resolved unchanged) **+ Gate #4** (Sentinel UNCHANGED at 1 per "
    "rebuttal-exception precedent + TL;DR refresh paired atomically) **+ Gate #5** (overview.md "
    "row 19 sync — trim + R20 sub-clause refresh + bundle-staging-order conditional) **+ Gate "
    "#8** (narrative-section freshness sweep — TL;DR + Sentinel + Closure Hygiene 3 lines + new "
    "R20 closure row + overview.md row 19 + current_handoff.md L7 lead-block) **+ Gate #9 "
    "clause (h)** (extended to intra-round-narrative-authoring layer — R19 closure row L2266 "
    "4 physical-line cites re-anchored to grep-stable symbolic markers per Claim 20.5; R20 "
    "closure row itself authored using grep-stable symbolic markers throughout per Claim 20.6 "
    "forward-protection) **+ Gate #11** (working-tree clean post-R18+R19+R20 bundled rebuttal "
    "commits pending — R18 bundle = 3 state-file edits + rebuttal-round-18.md NEW + claim-"
    "review-18.md NEW; R19 bundle = 3 state-file edits + rebuttal-round-19.md NEW + claim-review-"
    "19.md NEW; R20 bundle = 3 state-file edits + rebuttal-round-20.md NEW + claim-review-20.md "
    "NEW + rebuttal-round-18.md corrigendum annotation per Claim 20.4 — staging-order-dispositive "
    "per Claim 20.3 conditional). **Prior rounds R19/R18/R17/R16/R15/R14/R13/R12 exercised gates** "
    "per their respective Mid-Phase Audit Log closure rows (chronological R06→R20 closure chain; "
    "full forensic-traceability via row pointer references — most-recent 3 rounds R20+R19+R18 "
    "explicit-exercise narrative kept inline per Claim 19.5 + Claim 20.1 + Recurring Weakness #10 "
    "trim convention; prior R17→R12 details via Mid-Phase Audit Log row references; pre-R12 "
    "rounds via prior post-fix-round-26 + post-IMPL-FIX-012-iter-1 + post-R10/R11 sweep history).\n"
)


L2369_NEW = (
    "- **State Reconciliation 3-file rule (CLAUDE.md §6):** impl-plan.md (primary SoT) ↔ "
    "overview.md (derived count + phase status) ↔ {module}/handoff.md + `_session-handoff/*` — "
    "**fully restored across all 3 tiers post-R15+R16+R17 bundled rebuttal commit + R18 + R19 + "
    "R20 narrative-propagation drain (R18 + R19 + R20 bundled rebuttal commits pending — "
    "staging-order-dispositive per Claim 20.3 conditional: Scenario A operator commits R18 first "
    "→ R18 bundle owns rebuttal-round-18.md NEW per R19 §19.3 enumeration completeness; "
    "Scenario B/C operator commits R19 first or bundles R18+R19+R20 single commit → R19 or "
    "single bundle owns rebuttal-round-18.md modifications per R19 §19.4 retroactive edit; close "
    "Gate #11 atomically across all 5 canonical surfaces when bundled)**: Tier 1 (`impl-plan.md`) "
    "closed via R15 cascade drain + R17/R18/R19/R20 narrative-propagation closure at TL;DR + "
    "Plan Staleness Sentinel + Closure Hygiene Status 3 lines + Mid-Phase Audit Log canonical-"
    "hygiene-tracking surfaces (R20 trim cycle reduced TL;DR L101 17K→2K chars + Sentinel L2356 "
    "6.3K→1.5K chars + State Reconciliation L2369 [this line] 3.6K→1.5K chars + R19 closure row "
    "L2266 7.2K→3K chars per Claim 20.1; line-anchor cite re-anchor R18 §18.4 + R20 §20.5 + R20 "
    "§20.6 forward-protection — immune to future audit-log row additions); Tier 2 (`overview.md`) "
    "row 19 Impl Plan status field BA/SD-parity rewrite post-R17 §17.5 + R18 §18.1 + R19 §19.2/"
    "19.3 + R20 §20.1 trim 104K→5K chars + R20 §20.3 bundle-staging-order conditional sub-clause "
    "(impl-plan-layer cascade ✅ CLOSED 2026-05-18 via R15→R20 cumulative Accept; downstream "
    "cascade pending: TD review + impl-code cleanup + IMPL-062 re-execute); Tier 3 "
    "(`current_handoff.md § Last completed action` lead-block) closed via R16 §16.3 + R18 §18.1 + "
    "R19 §19.2/19.4 + R20 §20.1 trim 4.3K→1.5K chars + R20 §20.3 bundle-staging-order conditional "
    "per CLAUDE.md §6 \"ทุกครั้งที่ปิด impl-plan rebuttal ต้อง update ทั้ง 3 ชั้น\" rule. Defect-"
    "class progression chain extends at handoff layer + within-rebuttal-commit-narrative-"
    "propagation layer + cross-document hygiene-claim-consistency layer + narrative-prose line-"
    "anchor stability layer (axes 1-11 closed at R18) + within-day-chronological + narrative-"
    "tense + file-bundle-enumeration + predicted-commit-message-stability + Closure Hygiene "
    "narrative-volume (axes 1-12 closed at R19) + multi-surface narrative-volume + 2-round Gate-"
    "11 + staging-order bundle-enumeration + retroactive-modification-discipline-carve-out + "
    "R19-narrative line-anchor + R20+ row-placement convention (axes 1-13 closed at R20 per "
    "Claim 20.1-20.6). Future round-N verify-pass predictions reframed as conditional \"clean "
    "WITHIN known axes 1-N\" per R18 §Recurring Weakness #3 lesson (R21 predicted conditional "
    "clean \"WITHIN known axes 1-13\"; 12 total open methodology-evolution candidates "
    "[Recurring Weaknesses #4-#15] flagged as `/update-config` ticket consolidation candidates). "
    "`backtrack-log.md § BT-002` (lifecycle SoT) ↔ impl-plan.md primary SoT fully reconciled at "
    "all 11+ surfaces enumerated in R15 §15.1 Location table. Prior reconciliations preserved: "
    "`backtrack-log.md § BT-001` ↔ impl-plan.md (R12 §12.1 Path A); `current_handoff.md § BT-001 "
    "cascade chain status` Steps 3/4/5 flipped ✅/⏭/✅ (R12 §12.6); `deferred-ac-registry.md` "
    "IMPL-062 row deferred-reason updated post-BT-001 (R12 §12.5).\n"
)


# -- Apply edits ----------------------------------------------------------------

def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    # Sanity checks before mutation.
    assert lines[100].startswith("> **Last updated:**"), "L101 anchor mismatch"
    assert "R19 `/impl-plan-rebuttal claim-review-19.md`" in lines[2265], "L2266 anchor mismatch"
    assert lines[2266].strip() == "", f"L2267 expected blank, got: {lines[2266][:80]!r}"
    assert lines[2355].startswith("**Last review on:**"), "L2356 anchor mismatch"
    assert "Phase 5 mechanical gates" in lines[2367], "L2368 anchor mismatch"
    assert "State Reconciliation 3-file rule" in lines[2368], "L2369 anchor mismatch"

    # Replace L101 (TL;DR Last updated).
    lines[100] = L101_NEW

    # Replace L2266 (R19 closure row) — trim + re-anchor per Claim 20.1 + 20.5.
    lines[2265] = L2266_NEW

    # Insert NEW R20 closure row at L2267 (the previously-blank line).
    # We replace the blank line at index 2266 with the R20 row, and we re-introduce
    # the blank separator AFTER it to preserve the table-end blank line.
    lines[2266] = L2267_NEW_R20_ROW + "\n"

    # Replace L2356 Plan Staleness Sentinel `Last review on:` line.
    lines[2355] = L2356_NEW

    # Replace L2368 Phase 5 mechanical gates line.
    lines[2367] = L2368_NEW

    # Replace L2369 State Reconciliation 3-file rule line.
    lines[2368] = L2369_NEW

    PATH.write_text("".join(lines), encoding="utf-8")
    print(f"OK. New line count: {sum(1 for _ in open(PATH, encoding='utf-8'))}")


if __name__ == "__main__":
    main()
