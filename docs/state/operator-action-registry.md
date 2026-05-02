# Operator Action Registry

> Single source of truth for **User Input Required (UIR)** actions ที่ engineer ทำให้นอก agent sandbox ไม่ได้ — set env var, fetch API key from vendor portal, accept ToS, run privileged migration manually, flip feature flag in admin UI, provision DB user
> Read by `/impl-task` (HALTs on Pending entries before nominating new task), `/next` (Check 5.7 surfaces pending operator actions), `/impl-plan-review` (Dim #4 verifies AC env-var/secret references have UIR linkage)

> **Distinct from Deferred-AC Registry** — deferred-AC = "wait for external dependency (vendor / hardware) ≤ 14 days"; operator-action = "operator do this NOW (session-scoped) so engineer can resume current task"

> **PhoenicisNex Phase 1 baseline note (2026-05-02):** local-only sandbox + solo operator + no env var / secret / API key / cloud config consumer (per BA `01 § 6.2 Won't Permanent`). UIR triggers ที่ realistic ใน Phase 1 = **Strategy Tester data-pull confirmation + manual MT5 chart attach for smoke G2** เท่านั้น (engineer ระบุใน task notes แต่ไม่ register Pending row ที่นี่ — เพราะ operator action = trivial / non-blocking). Registry initialized empty + remains empty unless Phase 2 cloud journal / Telegram bot / multi-account configuration triggers added.

---

## Pending (operator must action before linked tasks resume)

| ID | Task | Action verb + object | Why agent cannot do it | How operator does it (link/command) | Opened | Resume task on completion |
|----|------|----------------------|------------------------|-------------------------------------|--------|---------------------------|
| _empty — registry initialized 2026-05-02_ | | | | | | |

---

## Done (operator confirmed; engineer verified)

| ID | Task | Action | Confirmed on | Verified-by evidence (artifact) |
|----|------|--------|--------------|---------------------------------|
| _empty_ | | | | |

---

## Rules

1. **Every UIR halt creates a Pending row** — engineer ต้อง register action; ห้าม halt + ล้มเลิก task เงียบๆ
2. **Operator confirms in chat OR by editing this file** — moving row from Pending → Done
3. **Engineer verifies action took effect** — typically via `[config-audit]` evidence kind (env var resolved at runtime, ไม่ใช่ hardcoded test value); ไม่มี verification = action ไม่ Done
4. **Linked task ปิด `[x]` ไม่ได้** until corresponding row Done — `/impl-task` Phase 3.3 Gate B blocks
5. **Pending rows surface ใน `/next` Check 5.7** — operator เห็น backlog of expected actions before nominating new task
6. **Plan reviewer checks** (Dim #4): ถ้า AC text references env var / secret / config flag + task ไม่มี UIR row + ไม่มี `[config-audit]` E-AC → HIGH finding (planner pre-authoring config-blind closure)

---

## PhoenicisNex-specific UIR triggers (Phase 1 — anticipated, not yet expected)

> ทำเมื่อจริงๆ encounter — **ไม่ pre-register** ที่นี่
>
> | Trigger | Action verb + object | Notes |
> |---------|----------------------|-------|
> | Strategy Tester data download (first-time setup) | "download EURUSD M1 ticks from broker history server in MT5 Tester → Symbols → EURUSD → DownloadTicks" | Required ก่อน IMPL-046 spike + IMPL-062 regression — operator opens MT5 + clicks DownloadTicks; engineer cannot do (interactive UI) |
> | MetaEditor warning suppression for `libs/` legacy includes | "open MetaEditor → Tools → Options → CodeStyler → set Suppress=warning_codeXX" | Affects G1 compile gate — only ถ้า legacy lib produces unsuppressable noise; engineer should attempt fix-in-code first |
> | MT5 build update prerequisite (≥ 3815) | "Help → Check Updates → upgrade if version < 3815" | Affects all 4 gates — pre-condition C-2 from BA |
>
> **Phase 2 trigger preview (out-of-scope ตอนนี้):** ถ้า cloud journal / Telegram / multi-account → fetch API key + set ENV → register Pending row.

---

## Schema reference

```yaml
id: OPS-NNN
task: IMPL-NNN
action: "verb + object — e.g., 'set ENV_FBS_API_KEY in .env.local'"
why_agent_cannot: "single-sentence — e.g., 'secret rotation outside repo / interactive vendor portal'"
how_operator_does_it: "URL or command snippet"
opened: YYYY-MM-DD
resume_task: IMPL-NNN  # which task unblocks once Done
verified_by: "evidence artifact path — typically docs/state/_session-handoff/<task>-evidence-*.md § config-audit"
```
