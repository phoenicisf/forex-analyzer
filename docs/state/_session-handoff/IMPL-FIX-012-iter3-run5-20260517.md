# IMPL-FIX-012 iter-3 — Run #5 EXECUTED; ADR-014 INTRODUCES 3rd FALSE-POSITIVE CLASS (BI pyramiding); cap-3 budget exhausted → escalation gate

**Date:** 2026-05-17
**Status:** 🔴 **iter-3 COMPLETE — Run #5 reached sim 2021-01-06 02:50:48 then HALTED via `circuit_breaker_pingpong` magic=214 (Slot_BI). This is EARLIER than the Jan-14 baseline halt class (iter-1/iter-2 chain). iter-3's ADR-014 dedup rules (b) same-event_type and (c) same-position both MISS the BI pyramiding pattern (close-tk12 + open-tk14 = different positions, different event types, but same magic+dir+tick). Run #5 confirms ADR-014 was insufficient AND introduced a NEW halt class fired EARLIER than the original blocker. cap-3 budget consumed: iter-1 ✅ Step 0 falsification + ADR-013 surgical, iter-2 ❌ ADR-013 partial (Jan-14 ✅, Jan-27 ❌), iter-3 ❌ ADR-014 regression (Jan-06 ❌). E-AC #1 NOT MET; E-AC #2 N/A. Per cap-3 sequencing in IMPL-FIX-012 task block: iter-3 fail → escalation gate to `/impl-plan-review all` or `/backtrack sd`.**
**Workflow:** `/impl-task IMPL-FIX-012` iter-3 (cap-3 budget exhausted; escalation pending operator decision)

---

## §1 — Diagnostic chain (this session)

1. **21:33:47 baseline** — terminal log size 101334866, no 5ph terminal running (PID 6916 = `5\` separate install per OPS-001 reverted note).
2. **21:35:09 launch attempt 1 (PowerShell `Start-Process`)** → process exited at +8s with 0 tester log growth. Terminal log decoded shows error pattern identical to iter-2 attempts 19:58/20:13/20:17 + tonight's earlier failure:
   ```
   OM  0  21:38:59.058  Tester  last test passed with result "some error after pass finished" in 0:00:00.000
   ```
   Diagnosis: Model=4 tick-cache verification fails on first launch ~70 min after operator's GUI refresh at 20:29-20:32 — cache went stale again (same pattern OPS-002 documented).
3. **21:38:54 launch attempt 2 (bash with hardcoded INI_WIN)** → identical failure pattern at +8s.
4. **21:40:01 launch attempt 3 (bash retry, same args)** → **✅ tester started successfully**. PID 3536 alive at +10s, log growing. The transient Model=4 tick-freshness verification cleared after 1-2 retries — operator GUI refresh was not strictly required this time.
5. **21:40:30** — `[ERROR][slot=CircuitBreaker][ev=ping_pong][magic=214]` fired at sim 2021-01-06 02:50:48 with `pos_i=12 pos_j=14 evt_i=1 evt_j=0`.
6. **21:45:35** — orchestrator decided to kill PID 3536 (HALTED_STABLE silent grind, AutoTesting at 10% = Jan-May 2021 window; per iter-2 precedent kill → no further useful data).
7. **21:46:21** — PID 3536 exited cleanly (kill via PowerShell Stop-Process). Monitor reported `EXITED — backtest done`.
8. **21:46:25 onward** — extracted journal (19 records, 12,462 bytes) + decoded tester log (15,293 lines from 5 MB this-run delta).

---

## §2 — Run #5 outcome (empirical)

| Field | Value |
|-------|-------|
| Launch (wall) | 2026-05-17 21:40:01 (Bash, INI_WIN cygpath-resolved) |
| Tester started (wall) | 2026-05-17 21:40:04.942 (Tester `automatical testing started`) |
| Halt (wall / sim) | wall=21:40:30.605 / **sim=2021-01-06 02:50:48.052** |
| Halt_stable (sim) | **2021-01-06 09:42:53.074** (~7 hr after halt; vs iter-2 May-25 silent-grind = much shorter HALTED_STABLE window) |
| Kill (wall) | 2026-05-17 21:45:35 (~5.5 min wall-clock after launch; AutoTesting at 10%) |
| Process exit (wall) | 2026-05-17 21:46:21 |
| `.ex5` build | mtime 2026-05-17 21:08:09 (= iter-3 commit `15ff985` G1 PASS 0err/0warn/4977 ms; 362,718 bytes; ADR-014 schema bump landed) |
| Headless config | `simulation/headless-tests/regression_5yr_g4.ini` (Model=4, FromDate 2021.01.01, ToDate 2025.12.31, Deposit=1000, Leverage=500, ShutdownTerminal=1, Visual=0) |
| **Halt event** | **`circuit_breaker_pingpong` magic=214 (BI) dir=0 delta=0s threshold=3s; pos_i=12 pos_j=14 evt_i=1 evt_j=0** |
| Sim-days past Jan-14 storm | **−8 sim days (NEGATIVE — halted 8 days BEFORE Jan-14)** ⇒ E-AC #1 NOT MET; ADR-014 introduced halt class fired earlier than baseline |
| Final balance | **$928.35** (from $1000 deposit = −$71.65 = −7.2%; rewrite Net Profit ≈ −$71.65) |
| Final equity at halt_stable | $928.35 (all positions closed; 0 lots; 0 floating P/L) |
| Drift vs $24.27M baseline | **|drift| = 100.0003%** (vs NFR-1.1 ≤ 25% target) ⇒ FAIL |
| Journal records | 19 (9 entry + 8 exit + 1 halt + 1 halt_stable) — schema-valid; sample 5 records validated against `trade-journal-schema.yaml` |

**Per-slot entry counts (pre-halt window, 5 sim days):**

| Slot | Entries | Notes |
|------|---------|-------|
| BI | 4 | tk=6, 9, 12, 14 — all pyramiding (`BI,pyr,1` comment) |
| C | 1 | tk=2 (`C,MA,N,1,SL`) — closed by `ForceCutloss` at 02:50:48 |
| M | 1 | tk=3 (`M,MA,N,1,SL`) — still open at halt |
| B | 1 | tk=5 (`B,anti,1`) — still open at halt |
| Q | 1 | tk=7 (`Q,MA,N,1,SL`) — still open at halt |
| K | 1 | tk=10 (`K,layer,1`) — still open at halt |

**Per-slot exit counts (pre-halt window):** BI=3 (tk=6, 9, 12 all `BI,close` — TP/SL hits), C=1 (`ForceCutloss`). Slot count at halt: K=1, M=1, Q=1, B=2, BI=2 (snapshot from `halt` record `portfolio_summary.slot_counts`).

**G4 BI SL fix verification:** all 4 BI entries have `sl != 0` (range 1.23699..1.23967) per ADR-009 parent-pip-anchored ✅ (G4 fix #2 working; same as Run #3/#4).

---

## §3 — Root cause of NEW Jan-06 false-positive (iter-3 regression)

The halt event differs from iter-1 (Run #2/#3) AND iter-2 (Run #4) in THREE axes:

| Axis | iter-1 Run #2/#3 (Jan-14) | iter-2 Run #4 (Jan-27) | **iter-3 Run #5 (Jan-06)** |
|------|--------------------------|------------------------|----------------------------|
| Sim timestamp | 2021-01-14 14:59:21 | 2021-01-27 15:45:07 | **2021-01-06 02:50:48** (8 days EARLIER than Jan-14 baseline) |
| Magic / Slot | 205 (H) dir=1 BUY closes | 205 (H) dir=0 SELL closes | **214 (BI) dir=0 SELL** |
| Close trigger | broker SL on tickets 71+72 BUY w/ identical SL=1.21311 hit same tick | EA-driven `OrderGroupStartWorkflow` (SafePort) batch-close of 2+ Slot_H SELL positions same tick | **EA-driven BI pyramiding: close-tk12 followed immediately by open-tk14 same tick (different positions, different event_types)** |
| Deal reason | `DEAL_REASON_SL` (broker-driven) | `DEAL_REASON_EXPERT` (EA-driven) | `DEAL_REASON_EXPERT` (EA-driven; close-tk12 was TP/SL hit, open-tk14 was BI pyramid scaling Evaluate-side) |
| ADR-013 fires? | ✗ skips (filter passes broker SL ≠ EXPERT) → halt | ✓ passes filter (EA-driven) → halt | ✓ passes filter (EA-driven) → halt |
| ADR-014 rule (b) `evt_i==evt_j`? | n/a (close+close mass-close; rule (b) WOULD skip but pre-iter-3 RecordOpen was never wired) | n/a (close+close mass-close; rule (b) WOULD skip if iter-3 wired) | ✗ does NOT skip (close=1 vs open=0 are DIFFERENT event types) |
| ADR-014 rule (c) `pos_i==pos_j`? | n/a | ✗ does NOT skip (different positions in mass-close) | ✗ does NOT skip (tk=12 vs tk=14 are different positions) |
| Result | halt | halt | **halt EARLIER than baseline class** |

ADR-014 ring-buffer with `RecordOpen` newly wired surfaces a **3rd false-positive class** that the ADR-014 dedup rules (b) and (c) explicitly DO NOT catch:

> **The "legitimate close+open same-tick pyramiding" pattern**: when Slot_BI's `_TryExit` closes one pyramid position (e.g., on TP/SL hit) and Slot_BI's `Evaluate` immediately opens a NEW pyramid scaling entry in the SAME magic+dir within Δ=0s threshold, CircuitBreaker sees:
> - i = close event (evt=1), magic=214, dir=0, position_id=12
> - j = open event (evt=0), magic=214, dir=0, position_id=14
> - same magic ✓, same dir ✓, Δ=0s ≤ threshold ✓
> - rule (b) skip same-event_type? evt_i=1 ≠ evt_j=0 → **does NOT skip** ✗
> - rule (c) skip same-position? pos_i=12 ≠ pos_j=14 → **does NOT skip** ✗
> - ⇒ CheckPingPong returns true ⇒ EA halts

The actual reason this is "not true ping-pong" is that **BI pyramiding** is a designed-behavior pattern where one pyramid-scale closes (taking partial profit or hit SL) and the slot's next-tick evaluator opens a new scaling entry to maintain pyramid structure. The two positions are NOT the "same logical trade re-opening" that ping_pong detector was designed to catch (the ping-pong intent was: bug where slot closes a position then immediately re-opens IT — same position, not new pyramid). ADR-014 rule (c) `pos_i==pos_j` was meant to handle the same-position case but pyramiding is a DIFFERENT-position case that legitimately fires the close+open at Δ=0s.

**iter-3 is structurally a regression vs iter-2:** by wiring `RecordOpen`, the ring buffer now contains both close and open events, and CheckPingPong sees close+open pairs at Δ=0s for ANY slot that does same-tick pyramid-scale (BI most prominently, possibly others). Pre-iter-3, the buffer only contained close events (so close+open patterns didn't trigger detection). The "fix" introduced a new failure mode.

---

## §4 — iter-3 AC results

| AC | Result | Evidence |
|----|--------|----------|
| E-AC #1 — "Run #5 reaches ≥ 3 sim months past Slot_H Jan-14 storm point without `circuit_breaker_pingpong` halt" | ❌ **NOT MET (REGRESSED)** | Reached Jan-06 (−8 sim days BEFORE Jan-14); halted EARLIER than baseline class; magic=214 BI dir=0 pos_i=12 pos_j=14 evt_i=1 evt_j=0 |
| E-AC #2 — "If Run #5 reaches sim 2025-12-31: drift ≤ 25%" | ❌ **N/A** | Didn't reach 2025-12-31 trigger condition; drift ≈ 100% at halt_stable ($928.35 vs $24.27M baseline) |
| Cap-3 budget status | **iter-3 ❌** (regression vs iter-2 — fires earlier than baseline); cap-3 budget consumed | iter-1 ✅ surgical + Step 0 falsification; iter-2 ❌ ADR-013 partial; iter-3 ❌ ADR-014 regression |

ACs stay `[ ]` in impl-plan.md. Deferred-AC P4 IMPL-FIX-012 stays Active (expiry 2026-05-28; 11 days slack). IMPL-062 E-AC #1+#2 stay deferred (paired bundle still blocked).

---

## §5 — Escalation gate triggered (per cap-3 sequencing)

Per IMPL-FIX-012 task block iter-3 Status (~impl-plan.md line 1984):

> **Cap-3 budget status: iter-1 ✅; iter-2 ❌; iter-3 patch ready (Step 3 verification pending operator).**
>
> Per `IMPL-FIX-012 task block` original authoring (impl-plan.md ~line 1978):
>
> > Cap-3 iteration; iter-1 ✅; iter-2/3 conditional. **Escalation gate at iter-3 fail → `/impl-plan-review all` or `/backtrack sd`.**

iter-3 Run #5 FAILS BOTH acceptance criteria (regressed vs iter-2 — halts earlier than baseline class). Per cap-3 sequencing the escalation gate fires.

**Two escalation paths (engineer recommends route, operator decides):**

### Path A — `/impl-plan-review all` (intra-plan re-decomposition)

Use case: the iter-1/-2/-3 chain has consistently treated `circuit_breaker_pingpong` false-positives as **producer-side filter problems** (DEAL_REASON in iter-1, triggering_function in iter-2 hypothesis, position_id + event_type dedup in iter-3). Run #5 demonstrates that **each fix surfaces a new false-positive class** — the problem is structural not patchable: the CircuitBreaker BR-3.6 ping-pong detector with threshold=3s on `(magic, dir)` matching is **inherently incompatible** with how the EA executes trades (mass-close + pyramid-scale + same-tick close+open are all legitimate patterns that look exactly like ping-pong from `(magic, dir, Δ≤3s)` perspective).

A plan-level intervention would re-decompose: **disable BR-3.6 ping-pong detector entirely** OR **shift detector to a structural signal** (e.g., same-position-id close+open within N seconds, which is the original ping-pong intent — this is the ADR-014 (c) rule but inverted: ping-pong = same-position re-open, not different-position close-then-new). Removing the detector entirely is allowed if BR-3.6 verification gate is also relaxed — that's a BA/SD-level decision.

### Path B — `/backtrack sd` (architectural change to BR-3.6 contract)

Use case: BR-3.6 ping-pong detector is enshrined as a system-level safety invariant in `docs/ba/04 § BR-3.6` and `docs/design-docs/02-04` references. Changing it (e.g., from `(magic, dir, Δ<3s)` to `(position_id, Δ<3s)` matching, or weakening it to advisory-only, or removing the structural halt-on-ping_pong contract) is an architectural change requiring SD update + ADR amendment + downstream propagation.

The user note 2026-05-17 (post-iter-2): "if iter-3 fails, the next step is to figure out whether BR-3.6 is the right shape at all" suggests Path B is the considered intent.

### Engineer recommendation

**Path B (`/backtrack sd`)** for the following reasons:

1. The iter-1→-2→-3 chain accumulated **3 distinct false-positive classes** with each "fix" introducing the next class. This pattern signals the underlying detector design is unsound, not that a 4th producer-side patch will suffice.
2. ADR-014's `rule (c) same-position` is **the inverse** of what ping-pong-detection actually should match: ping-pong = same position closed-then-re-opened (which rule (c) skips so it doesn't fire), while mass-close + pyramid-scale = different positions at same tick (which rule (c) DOESN'T skip so it DOES fire — wrong direction).
3. The legacy `PhoenicisN2.10_stable.mq5` (5-yr 2021-2025 baseline = $24.27M Net Profit) achieves this trading volume DESPITE all the mass-close + pyramid-scale + broker-SL patterns the rewrite trips on — because legacy doesn't have a ping-pong detector. The detector was introduced in the rewrite per BR-3.6 spec but its design doesn't match the trading patterns it's deployed against.
4. cap-3 iteration budget exhausted — engineer-side surgical patching has explored the producer-side, dedup-side, and event-wiring axes. The remaining axes (matching key redefinition, detector removal) cross the SD boundary.

---

## §6 — Cascade impact

- **IMPL-FIX-012 task** stays open with 3/3 S-AC `[x]` (Step 0 + Step 1 patch + Step 2 G1+G2) but 0/2 E-AC `[x]`. Cap-3 budget consumed — no more engineer-side iterations allowed without escalation closure.
- **Deferred-AC Registry P4 IMPL-FIX-012 row** stays Active (expiry 2026-05-28; 11 days slack). Risk-if-missed: 🔴 HIGH (NFR-1.1 acceptance signal blocker remains).
- **IMPL-062 task** stays open with 0/2 E-AC `[x]` (paired-bundle blocked; same expiry 2026-05-28).
- **Deferred-AC Registry P4 IMPL-062 row** stays Active. Renewal #2 of max 2 will trigger on 2026-05-28 if escalation hasn't resolved by then; renewal #3 attempt would force `/impl-plan-review all` per Phase 1.3.2.
- **IMPL-068 force-clear validation + IMPL-066 journal latency long-sample** stay blocked (paired-bundle gated on IMPL-062 numeric drain).
- **P2/P3/P4 Tier 2 Phase Gate** stays blocked (paired-bundle drain prerequisite).
- **MVP NFR-1.1 acceptance signal** stays unmet.

---

## §7 — Operator-action-registry

No OPS-NNN row registered this session. The 2-attempt launch failures at 21:35 + 21:38 were transient Model=4 tick-cache verification hiccups (same pattern as iter-2 pre-OPS-002), but unlike iter-2 the issue cleared on **retry without operator GUI intervention** — confirming OPS-002's underlying cause (cache staleness ≥ session-idle threshold) is now intermittent rather than reliably reproducible after a 1-2 hr idle window. No need to register OPS-003.

---

## §8 — Closure note (for impl-plan TL;DR + Status block)

**🔴 IMPL-FIX-012 iter-3 ❌ COMPLETE — Run #5 EXECUTED 2026-05-17 21:40-21:46 wall-clock; halted at sim 2021-01-06 02:50:48 via `circuit_breaker_pingpong` magic=214 (Slot_BI) dir=0 delta=0s threshold=3s; pos_i=12 pos_j=14 evt_i=1 evt_j=0. ADR-014's rules (b) same-event_type + (c) same-position both miss the BI pyramiding close-open same-tick pattern (different positions, different event_types). iter-3 REGRESSED vs iter-2 (halt at Jan-06 vs Jan-27). Final balance $928.35 (drift −100.0003%); 19 journal records (9 entry + 8 exit + 1 halt + 1 halt_stable). E-AC #1 NOT MET; E-AC #2 N/A. cap-3 budget consumed (iter-1 ✅ + iter-2 ❌ + iter-3 ❌). Per cap-3 sequencing the escalation gate fires → `/impl-plan-review all` or `/backtrack sd`. Engineer recommends `/backtrack sd` (BR-3.6 detector design is fundamentally incompatible with legitimate trading patterns: mass-close + pyramid-scale + broker-SL all look like ping-pong from `(magic, dir, Δ≤3s)` perspective; each producer-side patch surfaces the next class). Evidence: `_session-handoff/IMPL-FIX-012-iter3-run5-20260517.{md,jsonl,-tester-abridged.txt}` (NEW 3-artifact bundle).**
