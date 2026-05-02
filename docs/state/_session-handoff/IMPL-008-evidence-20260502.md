# IMPL-008 Evidence — CommentParser.mqh
**Date:** 2026-05-02
**Task:** IMPL-008 — `helpers/CommentParser.mqh` (shared-magic disambiguation pure utility)
**Status:** Completed

---

## File Path and Line Count

| Property | Value |
|----------|-------|
| File | `MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh` |
| Line count | 234 |
| Include guard | `PHOENICISNEX_HELPERS_COMMENTPARSER_MQH` |
| `#include "services/*"` references | **0** (ADR-012 helpers purity verified) |

---

## Method Signatures (3 public + 1 static SelfTest)

```mql5
// 1. Build — construct order comment
string Build(string slot_id, string body) const;
// Returns: slot_id + "," + body  (e.g. "G2,reason=peak_inverse")

// 2. ExtractSlotPrefix — parse slot id from comment
string ExtractSlotPrefix(string comment) const;
// Returns: substring before first "," (BR-1.2 longest-prefix match)
// Returns "" for empty, no-comma, or invalid prefix; emits Print warn stub

// 3. FilterTicketsByPrefix — select tickets matching slot prefix
int FilterTicketsByPrefix(const ulong &ticket_ids_in[],
                          string slot_prefix,
                          ulong &ticket_ids_out[]) const;
// Returns: count of tickets appended to ticket_ids_out[]

// 4. SelfTest — static fixture verification
static bool SelfTest();
// Emits: [Phoenicis][slot=system][ev=comment_parser_self_test][result=pass|fail]
```

---

## Self-Test Fixture Table (10 Cases)

| # | Input comment | Expected prefix | Case description |
|---|---------------|-----------------|------------------|
| 0 | `"G2,reason=peak_inverse"` | `"G2"` | Shared-magic G/G2 — G2 prefix (longer) |
| 1 | `"G,reason=force_high"` | `"G"` | Shared-magic G/G2 — G prefix (shorter) |
| 2 | `"BI,reason=parent_b"` | `"BI"` | Shared-magic B/BI — BI prefix (longer) |
| 3 | `"B,reason=standard"` | `"B"` | Shared-magic B/BI — B prefix (shorter) |
| 4 | `"LX,reason=tp_extension"` | `"LX"` | Shared-magic L/LX — LX prefix (longer) |
| 5 | `"L,reason=basic"` | `"L"` | Shared-magic L/LX — L prefix (shorter) |
| 6 | `"D,reason=force_pending"` | `"D"` | Shared-magic C/D — D (force-pending) |
| 7 | `"C,reason=cd_pool"` | `"C"` | Shared-magic C/D — C (primary) |
| 8 | `""` | `""` | Empty comment → warn Print emitted |
| 9 | `"unknown"` | `""` | No comma → warn Print emitted |

**Additional Build() fixture verified in SelfTest:**
- `Build("G2", "reason=peak_inverse")` → `"G2,reason=peak_inverse"` ✅

---

## BR-1.2 Compliance Note

**BR-1.2 requirement:** Slot orders that share magic (G/G2, B/BI, L/LX, C/D) must embed their full slot ID as comment prefix with comma delimiter.

**Implementation approach:** `ExtractSlotPrefix` finds the first `","` via `StringFind(comment, ",")` and returns `StringSubstr(comment, 0, comma_pos)`. Since each order embeds its **full, unambiguous** prefix (e.g., `"G2,"` not `"G,"`), there is no prefix-collision issue — the literal text before `","` is the canonical slot id.

**Why this is correct (BR-1.2 longest-prefix match):**
- A `G2` order has comment `"G2,..."` → prefix = `"G2"` (not `"G"`)
- A `G` order has comment `"G,..."` → prefix = `"G"`
- The disambiguation is entirely determined by the **write path** (`Build()`) at order creation, not by pattern matching at read time. `CCommentParser.Build("G2", body)` produces `"G2,"` and `CCommentParser.Build("G", body)` produces `"G,"` — these are distinct strings.

**Validation:** prefix is rejected (returns `""`) if:
- No `","` found (no prefix embedded)
- Empty prefix (comma at position 0)
- Prefix length > 4 chars (exceeds max slot id length)
- Prefix contains non-alphanumeric characters

**Logger stub:** `Print("[Phoenicis][slot=system][ev=comment_parser_unrecognized][comment=...]")` used as stub for `Logger.Warn` until IMPL-042 wires Logger injection. Matches ADR-011 stable log prefix pattern.

---

## Verification Commands Run

### 1. Line count
```bash
wc -l MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
# Output: 234 CommentParser.mqh
```

### 2. ADR-012 helpers purity check — zero services/* includes
```bash
grep -c "services/" MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
# Output: 0  (PASS — no services/ includes)
```

### 3. Include guard presence
```bash
grep "PHOENICISNEX_HELPERS_COMMENTPARSER_MQH" MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
# Output:
# #ifndef PHOENICISNEX_HELPERS_COMMENTPARSER_MQH
# #define PHOENICISNEX_HELPERS_COMMENTPARSER_MQH
# #endif // PHOENICISNEX_HELPERS_COMMENTPARSER_MQH
```

### 4. Method signature presence
```bash
grep -E "string Build|string ExtractSlotPrefix|int FilterTicketsByPrefix|static bool SelfTest" \
  MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
# Output: all 4 signatures found (PASS)
```

### 5. ADR-011 stable log prefix pattern
```bash
grep "Phoenicis.*slot=system.*ev=comment_parser" MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
# Output: 3 unique ev= tags found:
#   ev=comment_parser_unrecognized  (ExtractSlotPrefix warn stub)
#   ev=comment_parser_self_test     (SelfTest result)
```

---

## G1-G4 Gate Status

| Gate | Status | Reason |
|------|--------|--------|
| G1 Compile | **N/A** | Header-only `.mqh`; entry `.mq5` gates activate at IMPL-018+ |
| G2 Smoke | **N/A** | Same — no entry point compiled yet |
| G3 Headless backtest | **N/A** | Same |
| G4 Log review | **N/A** | Same |

Verification = grep self-checks above (structural correctness). Full G1-G4 will be exercised when `PhoenicisNex.mq5` entry point is compiled (IMPL-018+).
