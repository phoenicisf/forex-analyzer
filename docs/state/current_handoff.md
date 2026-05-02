# PhoenicisNex — Current Handoff

> Single-project handoff per CLAUDE.md §6. Updated end-of-task / end-of-session / cross-day.

## Last completed action

**Code Review Round 01 + Fix Round 01 (closed 2026-05-02)**
**Phase:** P1 — Foundation (13/17 tasks closed; review/fix overlay on IMPL-001..005, 007..009, 011, 012, 014, 015, 042)
**Mode:** `/impl-review-fix review-round-01.md` — orchestrator Opus 4.7, serial in-process (no parallel fan-out — single service `ea`).

### What was reviewed + fixed

Review-round-01 raised **11 findings** (CRITICAL 2 / HIGH 3 / MEDIUM 4 / LOW 2). All 11 accepted (0 reject, 0 partial). 4 source files modified across 4 commit groups; JsonWriter `SelfTest` extended +3 assertions.

#### Fix group G1 — `services/IndicatorService.mqh` (5 fixes)
- **01.1 CRITICAL:** `CreateHandles` cleanup loop on partial-failure path — releases all valid handles before `return false` (prevents 23-handle leak on INIT_FAILED retry).
- **01.2 CRITICAL:** `iCustom` ZigZag path `"ZigZag"` → `"Examples\\ZigZag"` (bundled MT5 ZigZag at `MQL5/Indicators/Examples/ZigZag.ex5`).
- **01.4 HIGH:** Boot-time fail-fast log call `Logger.Error` → `Logger.ErrorBypassThrottle` (matches BootstrapValidator pattern; ADR-011 boot-time bypass).
- **01.6 MEDIUM:** Header doc "10-entry LRU scan cache" → "10-entry FIFO scan cache (insertion-order evict)" + tradeoff note + IMPL-006-cachedscan upgrade pointer.
- **01.7 MEDIUM:** `CachedScan` cache miss now logs Warn `cached_scan_unwired` + returns 0.0 + does NOT insert (fail-loud; was silent wrong-result via `m_handles[0]` regardless of key).

#### Fix group G2 — `services/PortfolioState.mqh`
- **01.5 HIGH:** `Init()` defensive guard — calls `ReleaseAll()` if `m_magic_count > 0` before reset (prevents 17 SlotState* leak on MT5 re-init / CleanupPartialInit re-attempt).

#### Fix group G3 — `helpers/JsonWriter.mqh`
- **01.9 MEDIUM:** `EscapeString` extended with control-char loop — RFC 8259 §7 compliance (escape U+0000..U+001F as `\uXXXX` after the 5 char-class StringReplaces).
- **01.10 LOW:** Apply `EscapeString` to JSON keys across 6 WriteX methods (WriteString/Int/Double/Bool/Null/Raw).
- **01.11 LOW:** `WriteDateTime` epoch fallback synthesizes `YYYY-MM-DDTHH:MM:SSZ` via `TimeToStruct` + StringFormat → `WriteString` (was emitting bare int — schema violation).
- **SelfTest updates:** case 11 rewritten to assert ISO synth path; case 13 added (control-char escape ``); case 14 added (key escape with `"` and `\`).

#### Fix group G4 — doc drift
- **01.3 HIGH:** `helpers/CommentParser.mqh` shared-magic doc magic numbers 202/216/213 → 208/214/211 (canonical via EnumTypes MAGIC_G/B/L) + cross-link note.
- **01.8 MEDIUM:** `core/BootstrapValidator.mqh` ValidateInputs header "43 individual if-blocks" → "39 individual if-blocks (matches body Guards 1..39)" + breakdown 17+11+8+3=39.

### Files changed

- `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh` (5 edit sites)
- `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh` (1 edit site — `Init()`)
- `MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh` (10 edit sites: EscapeString rewrite + 6 key escapes + WriteDateTime + SelfTest case 11/13/14)
- `MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh` (1 doc block)
- `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh` (1 doc block)
- `docs/code-review/fix-round-01.md` (created — full fix report)
- `docs/state/overview.md` (Code Review row populated)
- `docs/state/current_handoff.md` (this file — overwritten)

### Tests added/updated

- `CJsonWriter::SelfTest` — case 11 rewritten + cases 13 (control-char) + 14 (key-escape) added. Total assertions: 11 → 14. Runs at IMPL-018+ wire-up.
- No new SelfTest for IndicatorService / PortfolioState (header-only fixes; runtime verification gated by IMPL-018+ entry .mq5 per existing precedent).

### 4-Gate Definition of Done

G1 (Compile) / G2 (Smoke) / G3 (Headless) / G4 (Log review) — **N/A for header-only `.mqh` in isolation** per TD-02 §13.1 + IMPL-001..042 precedent. Gates activate at IMPL-018+ when entry `.mq5` lands. All Round 01 fixes are structurally sound (Edit + Read verified); empirical verification (especially 01.2 ZigZag path on stock MT5 install) deferred to IMPL-018+ headless smoke run — this is the existing precedent, not regression of this round.

### Cross-state checks

- `impl-plan.md` Forbidden Closure Pattern grep = 0 hits sustained ✅ (Code Review Dim #11 originally PASS — fixes did not change AC closure pattern).
- No task `[x]` AC needs to flip back to `[ ]` (no functional regression introduced; all fixes are correctness improvements + doc alignment).
- No Deferred-AC Registry mutation (registry empty per Phase 1 baseline).
- No new ADR (all fixes within existing ADR-003/005/006/007/011 + TD-02 §5/§7 contracts).

### Known issues / tech debt

- **CachedScan true LRU upgrade** still tracked at IMPL-006-cachedscan TODO (option B = doc-fix-only chosen this round; full LRU implementation deferred to MarketContextBuilder landing).
- Fix Round 01 commits not yet created — next session will commit per the 4 fix groups.
- `[config-audit]` E-AC kind remains N/A for Phase 1 (no env-var/secret consumer; promotes if Phase 2 cloud journal added).

### Next suggested task

**Recommendation: `/impl-task IMPL-046`** — M [ea] atomic-write spike, Evolution E1 risk gate.

P1 status unchanged (13/17 task closures). Round 01 review surface acted as Mid-Phase Audit checkpoint — confirmed no Forbidden Closure Pattern violations + no AC drift.

P1 ready work:
- **IMPL-046** (M [ea] atomic-write spike) — **Evolution E1 risk gate**; unblocks IMPL-010 + IMPL-047/048/049 chain. Recommended next.
- **IMPL-006** (M [ea] MarketContextBuilder) — deps green via IMPL-005 (CachedScan now fail-loud — caller will see `cached_scan_unwired` Warn until IDX↔key mapping wired this task).
- **IMPL-016** (XS [ea] BootstrapValidator::ValidateSymbol body) — bundle into existing file.

After IMPL-046 lands, recommend `/impl-plan-review all` (Plan Staleness Sentinel still at 13/10 closures-since-last-review).
