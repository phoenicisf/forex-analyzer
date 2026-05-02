# PhoenicisNex Security Rules

## Methodology Baseline (OWASP-aligned, anti-pattern catalog)
- **ห้าม** hardcode secrets, API keys, connection strings, credentials in source
- **ห้าม** string concatenation in any data sink — use parameterized APIs
- **ห้าม** return sensitive data (passwords, stack traces, internal paths) to external surfaces
- **ห้าม** trust client/external input without explicit validation at boundary
- **ห้าม** silent error swallow — every catch path must log severity + escalate
- Automated enforcement: pre-commit hooks (when added) + manual code review checklist

## MQL5/MT5 Stack-Specific Rules

### Authentication & Network Boundary
- **ห้าม** open network listener / external HTTP / `WebRequest` / external DLL ใน Phase 1 — `#import` directives เฉพาะ MQL5 standard library/system <!-- source: NFR-7.2 = 0 external DLLs -->
- **No auth flow needed** — solo operator, no users, no remote API; broker login is MT5 platform concern (handled by user via terminal UI, not by EA)
- **Symbol whitelist:** `OnInit` MUST reject if `_Symbol != "EURUSD"` 100% — log via `Logger::Error` + return `INIT_FAILED` (no exception, no silent skip) <!-- source: NFR-5.3 + FR-1.2 -->
- **Phase 2 trigger:** if user adds cloud journal sync / Telegram / multi-account → revisit Security NFR (auth, transport encryption, key management) per BA `03 § 5 Note` — currently out-of-scope

### Halt + Failure Surfacing (no silent failures)
- **ห้าม** silent `ExpertRemove()` — every halt path MUST `Alert()` MT5 native popup + write journal entry + log `[ev=halt]` <!-- source: NFR-5.1 + CodeWiki §6.2 P2.3 -->
- **ห้าม** `INVALID_HANDLE` from indicator handles propagate to OnTick — OnInit MUST validate all ~25 handles, fail-fast 100% with `IndicatorService::HandleCount()` audit <!-- source: NFR-3.2 + FR-7.6 -->
- All halt-trigger paths route through `EAState::SetHalted(reason)` BEFORE the next exit pass (per ADR-010 + Claim 01.3)
- Logger escalation: N-consecutive errors per `[slot]` tag → automatic `Alert()` escalation per ADR-011 (anti-spam ≤ 1 per slot per session per ADR-008)

### State + Journal Integrity
- **ห้าม** flat write `state.json` — use `helpers/AtomicFile.mqh` (write temp `.tmp` → fsync → rename) per ADR-007 Option A; Option B fallback documented in TD-02 §4.4 <!-- source: ADR-007 + NFR-3.1 -->
- State write MUST survive simulated mid-write kill 100/100 trials (NFR-3.1 verification)
- Journal write `[5 ms p99]` cap per NFR-2.2 — overshoot = log warn + continue (degrade-but-continue, never block tick)
- All persisted JSON validated against schema in `docs/api-specs/{state-persistence-schema,trade-journal-schema}.yaml` — drift = CRITICAL finding

### Local-only Data Discipline
- Phase 1: ALL data stays in MT5 sandbox `MQL5/Files/PhoenicisNex/` — no cloud sync, no telemetry, no external upload
- **ห้าม** log/persist data to any path outside the sandbox
- **ห้าม** include personal account number / login in journal records (use anonymized `account_id` hash if needed Phase 2)
