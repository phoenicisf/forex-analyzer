//+------------------------------------------------------------------+
//| TradeJournal.mqh — JSON-Lines journal service scaffold          |
//| Layer:   services/ — append-only local journal per ADR-006      |
//| Source:  TD-02 §5.5 / §9.5, ADR-006, FR-4.1, FR-4.3, NFR-2.2    |
//+------------------------------------------------------------------+
//| IMPL-066 extension (NFR-2.2 journal write latency measurement)  |
//| Adds ≥200-sample ring buffer, running aggregates, per-event-type |
//| breakdown map (linear-probe, 16 buckets), EmitLatencyReport()   |
//| (periodic every 1000 writes + final at Close), and sidecar JSON |
//| report at PhoenicisNex/journal/<mode>/latency-report-<ISO>.json |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_TRADEJOURNAL_MQH
#define PHOENICISNEX_SERVICES_TRADEJOURNAL_MQH

#include "PortfolioState.mqh"
#include "Logger.mqh"
#include "StatePersistence.mqh"
#include "../domain/IHaltSink.mqh"
#include "../helpers/JsonWriter.mqh"
#include "../helpers/Timestamp.mqh"

#define JOURNAL_SCHEMA_VERSION 1
#define JOURNAL_HALT_THRESHOLD 10
#define JOURNAL_OVERSHOOT_WINDOW 10
#define JOURNAL_WARN_LATENCY_MS 5

//+------------------------------------------------------------------+
//| JournalEvent — caller-populated payload; TradeJournal fills      |
//| schema_version + mode internally per ADR-006                     |
//+------------------------------------------------------------------+
struct JournalEvent
  {
   datetime          timestamp_seconds;
   ulong             timestamp_microseconds;

   string            event_type;
   string            slot_id;
   int               magic;
   ulong             ticket_id;
   string            symbol;
   string            order_type;
   double            lot;
   double            price;
   double            sl;
   double            tp;
   string            comment;
   string            signal_context;
   string            triggering_function;
   ulong             parent_ticket_id;
   string            halt_reason;
   int               pending_age_bars;
  };

class CMarketContextBuilder;

//+------------------------------------------------------------------+
//| CTradeJournal                                                    |
//|                                                                   |
//| Step-2 scaffold only: data model + dependency graph + path       |
//| contracts. File-write / rotation / failure accounting logic      |
//| lands in later decomposition steps.                              |
//+------------------------------------------------------------------+
class CTradeJournal
  {
private:
   int                    m_handle;
   bool                   m_is_tester;
   datetime               m_current_month;
   string                 m_active_path;
   string                 m_run_id;
   ulong                  m_overshoot_window[JOURNAL_OVERSHOOT_WINDOW];
   int                    m_overshoot_idx;
   int                    m_consecutive_failures;

   //--- IMPL-066: NFR-2.2 ≥200-sample latency aggregates
   ulong                  m_latency_total_us;
   ulong                  m_latency_max_us;
   int                    m_latency_count;
   ulong                  m_latency_samples[200];    // ring buffer, last 200 elapsed_us
   int                    m_latency_samples_idx;
   int                    m_latency_samples_filled;  // clamps to ≤ 200

   //--- IMPL-066: per-event-type breakdown (linear-probe map, max 16 buckets)
   string                 m_evtype_keys[16];
   int                    m_evtype_counts[16];
   ulong                  m_evtype_total_us[16];
   int                    m_evtype_used;

   CMarketContextBuilder *m_ctx_builder;
   CPortfolioState       *m_portfolio;
   CLogger               *m_logger;
   CStatePersistence     *m_state;
   IHaltSink             *m_halt_sink;       // ADR-006 RPO escalation (Finding 03.6)

public:
                        CTradeJournal()
      : m_handle(INVALID_HANDLE),
        m_is_tester(false),
        m_current_month(0),
        m_active_path(""),
        m_run_id(""),
        m_overshoot_idx(0),
        m_consecutive_failures(0),
        m_ctx_builder(NULL),
        m_portfolio(NULL),
        m_logger(NULL),
        m_state(NULL),
        m_halt_sink(NULL),
        m_latency_total_us(0),
        m_latency_max_us(0),
        m_latency_count(0),
        m_latency_samples_idx(0),
        m_latency_samples_filled(0),
        m_evtype_used(0)
     {
      ArrayInitialize(m_overshoot_window, 0);
      ArrayInitialize(m_latency_samples, 0);
      ArrayInitialize(m_evtype_counts, 0);
      ArrayInitialize(m_evtype_total_us, 0);
      for(int i = 0; i < 16; i++)
         m_evtype_keys[i] = "";
     }

   void                 Init(CMarketContextBuilder *cb,
                             CPortfolioState *port,
                             CLogger *logger,
                             CStatePersistence *state);

   //--- Phase-2 setter — Orchestrator wires CEAState (or any IHaltSink)
   //    after both services exist (IMPL-018+ Composition Root). NULL-safe:
   //    HandleWriteFailure simply skips escalation if sink not yet wired.
   void                 SetHaltSink(IHaltSink *sink) { m_halt_sink = sink; }

   bool                 Open();
   void                 WriteEvent(const JournalEvent &ev);
   void                 RotateIfNeeded();
   void                 Close();

   //--- IMPL-066: emit aggregated latency summary to Logger (+ sidecar JSON)
   //    Called at: (1) every 1000th write — periodic, Logger-only (cheap).
   //               (2) final emit in Close() — full Logger + sidecar JSON.
   //    fix-round-17 § 17.4 — sidecar I/O (FileOpen/Write/Close ≈ 1–3 ms)
   //    on the hot-path self-pollutes NFR-2.2 p95 measurement; gate sidecar
   //    write to `emit_sidecar=true` (final emit only).
   void                 EmitLatencyReport(bool emit_sidecar = true);

   bool                 ShouldHaltSustained(int &out_consecutive) const
     {
      out_consecutive = m_consecutive_failures;
      return m_consecutive_failures >= JOURNAL_HALT_THRESHOLD;
     }

private:
   void                 BuildRecord(const JournalEvent &ev, string &out_json);
   string               BuildIndicatorSnapshotSubset(string slot_id);
   string               BuildPortfolioSummary();
   void                 HandleWriteFailure(string reason);
   void                 ResetConsecutiveOnSuccess();
   void                 TrackLatency(ulong elapsed_us, const string &event_type);

   string               LiveDirectory() const;
   string               TesterDirectory() const;
   bool                 EnsureDirectories() const;
   string               MonthlyKey(datetime now_s) const;
   string               BuildLivePath(datetime now_s) const;
   string               BuildTesterRunId(datetime now_s, ulong micro) const;
   string               BuildTesterPath() const;
  };

//+------------------------------------------------------------------+
//| Init — store dependencies and reset runtime counters             |
//+------------------------------------------------------------------+
void CTradeJournal::Init(CMarketContextBuilder *cb,
                         CPortfolioState *port,
                         CLogger *logger,
                         CStatePersistence *state)
  {
   m_ctx_builder          = cb;
   m_portfolio            = port;
   m_logger               = logger;
   m_state                = state;
   // m_halt_sink intentionally NOT reset here — Orchestrator may call
   // SetHaltSink() before or after Init(); both orderings must work.
   m_handle               = INVALID_HANDLE;
   m_is_tester            = (bool)MQLInfoInteger(MQL_TESTER);
   m_current_month        = 0;
   m_active_path          = "";
   m_run_id               = "";
   m_overshoot_idx        = 0;
   m_consecutive_failures = 0;
   ArrayInitialize(m_overshoot_window, 0);
   // IMPL-066: reset latency aggregates on re-init
   m_latency_total_us      = 0;
   m_latency_max_us        = 0;
   m_latency_count         = 0;
   m_latency_samples_idx   = 0;
   m_latency_samples_filled= 0;
   m_evtype_used           = 0;
   ArrayInitialize(m_latency_samples, 0);
   ArrayInitialize(m_evtype_counts, 0);
   ArrayInitialize(m_evtype_total_us, 0);
   for(int i = 0; i < 16; i++)
      m_evtype_keys[i] = "";
  }

//+------------------------------------------------------------------+
//| Open — Step-2 scaffold picks path contract only                  |
//+------------------------------------------------------------------+
bool CTradeJournal::Open()
  {
   datetime now_s = TimeCurrent();
   ulong micro    = GetMicrosecondCount();

   m_is_tester = (bool)MQLInfoInteger(MQL_TESTER);
   if(m_is_tester)
     {
      if(StringLen(m_run_id) == 0)
         m_run_id = BuildTesterRunId(now_s, micro);
      m_active_path = BuildTesterPath();
      m_current_month = now_s;
     }
   else
     {
      m_current_month = now_s;
      m_active_path   = BuildLivePath(now_s);
     }

   if(!EnsureDirectories())
     {
      if(m_logger != NULL)
         m_logger.Error("system", "journal_dir_fail", 0,
                        StringFormat("base=%s", m_is_tester ? TesterDirectory() : LiveDirectory()));
      return false;
     }

   if(m_handle != INVALID_HANDLE)
     {
      FileFlush(m_handle);
      FileClose(m_handle);
      m_handle = INVALID_HANDLE;
     }

   m_handle = FileOpen(m_active_path,
                       FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(m_handle == INVALID_HANDLE)
     {
      if(m_logger != NULL)
         m_logger.Error("system", "journal_open_fail", 0,
                        StringFormat("path=%s err=%d", m_active_path, GetLastError()));
      return false;
     }

   FileSeek(m_handle, 0, SEEK_END);
   return true;
  }

//+------------------------------------------------------------------+
//| WriteEvent — Step-2 stub; serialization lands in Step 3          |
//+------------------------------------------------------------------+
void CTradeJournal::WriteEvent(const JournalEvent &ev)
  {
   RotateIfNeeded();

   if(m_handle == INVALID_HANDLE && !Open())
     {
      HandleWriteFailure("open_failed_before_write");
      return;
     }

   string record = "";
   BuildRecord(ev, record);

   ulong started_us = GetMicrosecondCount();
   FileSeek(m_handle, 0, SEEK_END);
   uint written = FileWriteString(m_handle, record);
   if(written < (uint)StringLen(record))
     {
      HandleWriteFailure(StringFormat("path=%s written=%u expected=%d err=%d",
                                      m_active_path, written, StringLen(record), GetLastError()));
      return;
     }

   FileFlush(m_handle);
   ulong ended_us = GetMicrosecondCount();
   ulong elapsed_us = (ended_us >= started_us) ? (ended_us - started_us) : 0;
   TrackLatency(elapsed_us, ev.event_type);
   ResetConsecutiveOnSuccess();
  }

//+------------------------------------------------------------------+
//| RotateIfNeeded — Step-2 stub; live rotation lands in Step 3      |
//+------------------------------------------------------------------+
void CTradeJournal::RotateIfNeeded()
  {
   if(m_is_tester)
      return;

   datetime now_s = TimeCurrent();
   if(MonthlyKey(now_s) == MonthlyKey(m_current_month))
      return;

   Close();
   m_current_month = now_s;
   m_active_path   = BuildLivePath(now_s);
   Open();
  }

//+------------------------------------------------------------------+
//| Close — emit final latency report, then reset handle/path state  |
//+------------------------------------------------------------------+
void CTradeJournal::Close()
  {
   // IMPL-066: final emit at session end (trigger 2 of 2)
   if(m_latency_count > 0)
      EmitLatencyReport();

   if(m_handle != INVALID_HANDLE)
     {
      FileFlush(m_handle);
      FileClose(m_handle);
     }
   m_handle = INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//| BuildRecord — TD/ADR field contract stub                         |
//+------------------------------------------------------------------+
void CTradeJournal::BuildRecord(const JournalEvent &ev, string &out_json)
  {
   CJsonWriter w;
   w.Begin();
   w.WriteString("timestamp", FormatTimestampWithMs(ev.timestamp_seconds,
                                                    ev.timestamp_microseconds));
   w.WriteInt("schema_version", JOURNAL_SCHEMA_VERSION);
   w.WriteString("mode", m_is_tester ? "tester" : "live");
   w.WriteString("event_type", ev.event_type);
   w.WriteString("slot_id", ev.slot_id);
   w.WriteInt("magic", ev.magic);
   w.WriteString("symbol", ev.symbol);
   w.WriteString("signal_context", ev.signal_context);
   w.WriteRaw("indicator_snapshot", BuildIndicatorSnapshotSubset(ev.slot_id));
   w.WriteRaw("portfolio_summary", BuildPortfolioSummary());
   w.WriteString("triggering_function", ev.triggering_function);
   if(ev.ticket_id != 0)
      w.WriteInt("ticket_id", (long)ev.ticket_id);
   else
      w.WriteNull("ticket_id");
   if(StringLen(ev.order_type) > 0)
      w.WriteString("order_type", ev.order_type);
   else
      w.WriteNull("order_type");
   if(ev.ticket_id != 0 || ev.event_type == "entry" || ev.event_type == "exit" ||
      ev.event_type == "modify" || ev.event_type == "reject" || ev.event_type == "discovered")
      w.WriteDouble("lot", ev.lot, 2);
   else
      w.WriteNull("lot");
   if(ev.ticket_id != 0 || ev.event_type == "entry" || ev.event_type == "exit" || ev.event_type == "modify")
      w.WriteDouble("price", ev.price, _Digits);
   else
      w.WriteNull("price");
   if(ev.ticket_id != 0 || ev.event_type == "entry" || ev.event_type == "modify")
      w.WriteDouble("sl", ev.sl, _Digits);
   else
      w.WriteNull("sl");
   if(ev.ticket_id != 0 || ev.event_type == "entry" || ev.event_type == "modify")
      w.WriteDouble("tp", ev.tp, _Digits);
   else
      w.WriteNull("tp");
   //--- Finding 04.5: schema `comment` has maxLength: 32 (per
   //    trade-journal-schema.yaml). Clamp at the writer boundary rather than
   //    trust upstream slot caller; emit a Warn with original length so any
   //    truncation remains forensically visible (IMPL-068 QA).
   if(StringLen(ev.comment) > 0)
     {
      string c = ev.comment;
      if(StringLen(c) > 32)
        {
         if(m_logger != NULL)
            m_logger.Warn("system", "journal_comment_truncated", 0,
                          StringFormat("orig_len=%d slot=%s ticket=%I64u",
                                       StringLen(c), ev.slot_id, ev.ticket_id));
         c = StringSubstr(c, 0, 32);
        }
      w.WriteString("comment", c);
     }
   else
      w.WriteNull("comment");
   if(ev.parent_ticket_id != 0)
      w.WriteInt("parent_ticket_id", (long)ev.parent_ticket_id);
   else
      w.WriteNull("parent_ticket_id");
   if(StringLen(ev.halt_reason) > 0)
      w.WriteString("halt_reason", ev.halt_reason);
   else
      w.WriteNull("halt_reason");
   //--- Finding 04.6: gate by event_type (consistent with lot/price/sl/tp
   //    sibling gates) rather than value. Lets readers disambiguate
   //    "absent" (null) from "explicitly age=0" (legitimate at boundary).
   if(ev.event_type == "pending_force_clear")
      w.WriteInt("pending_age_bars", ev.pending_age_bars);
   else
      w.WriteNull("pending_age_bars");
   w.End();
   out_json = CJsonWriter::BuildJsonLine(w.ToString());
  }

//+------------------------------------------------------------------+
//| BuildIndicatorSnapshotSubset — schema-valid empty object stub    |
//|                                                                  |
//| Finding 03.5: real subset extraction requires IMPL-018+ Orchestrator|
//| to cache the per-tick MarketContext snapshot and inject it here  |
//| (CMarketContextBuilder::Build returns by value per ADR-004).     |
//| Tracked in docs/state/deferred-ac-registry.md row IMPL-043 /     |
//| indicator_snapshot. Returns "{}" — schema-valid empty object,    |
//| no JSON parse error, but FR-3.4 forensic context absent until    |
//| wired.                                                            |
//+------------------------------------------------------------------+
string CTradeJournal::BuildIndicatorSnapshotSubset(string slot_id)
  {
   slot_id = slot_id;
   return "{}";
  }

//+------------------------------------------------------------------+
//| BuildPortfolioSummary — schema-shape placeholder                  |
//+------------------------------------------------------------------+
string CTradeJournal::BuildPortfolioSummary()
  {
   CJsonWriter slot_counts;
   slot_counts.Begin();
   if(m_portfolio != NULL)
     {
      int magics[PHOENICISNEX_MAGIC_COUNT] = {
         MAGIC_CD, MAGIC_F, MAGIC_H, MAGIC_J, MAGIC_K, MAGIC_G, MAGIC_GO, MAGIC_M, MAGIC_L,
         MAGIC_Q, MAGIC_R, MAGIC_B, MAGIC_BR, MAGIC_I, MAGIC_S, MAGIC_P, MAGIC_T
      };
      for(int i = 0; i < PHOENICISNEX_MAGIC_COUNT; i++)
        {
         SlotState *state = m_portfolio.GetByMagic(magics[i]);
         if(state == NULL)
            continue;
         for(int j = 0; j < ArraySize(state.slot_ids); j++)
            slot_counts.WriteInt(state.slot_ids[j], state.buy_count + state.sell_count);
        }
     }
   slot_counts.End();

   CJsonWriter summary;
   summary.Begin();
   double total_lots = 0.0;
   if(m_portfolio != NULL)
     {
      int magics[PHOENICISNEX_MAGIC_COUNT] = {
         MAGIC_CD, MAGIC_F, MAGIC_H, MAGIC_J, MAGIC_K, MAGIC_G, MAGIC_GO, MAGIC_M, MAGIC_L,
         MAGIC_Q, MAGIC_R, MAGIC_B, MAGIC_BR, MAGIC_I, MAGIC_S, MAGIC_P, MAGIC_T
      };
      for(int i = 0; i < PHOENICISNEX_MAGIC_COUNT; i++)
        {
         SlotState *state = m_portfolio.GetByMagic(magics[i]);
         if(state != NULL)
            total_lots += state.total_lots;
        }
     }
   summary.WriteDouble("total_lots", total_lots, 2);
   summary.WriteDouble("total_floating_pl",
                       (m_portfolio != NULL) ? m_portfolio.TotalFloatingPL() : 0.0, 2);
   summary.WriteDouble("equity", AccountInfoDouble(ACCOUNT_EQUITY), 2);
   summary.WriteDouble("balance", AccountInfoDouble(ACCOUNT_BALANCE), 2);
   summary.WriteRaw("slot_counts", slot_counts.ToString());
   summary.End();
   return summary.ToString();
  }

//+------------------------------------------------------------------+
//| HandleWriteFailure / ResetConsecutiveOnSuccess — scaffold hooks  |
//+------------------------------------------------------------------+
void CTradeJournal::HandleWriteFailure(string reason)
  {
   m_consecutive_failures++;
   if(m_state != NULL)
      m_state.IncrementJournalFailures();
   if(m_logger != NULL)
      m_logger.Error("system", "journal_write_fail", 0, reason);

   //--- ADR-006 RPO escalation (Finding 03.6 + 04.3): self-halt when counter
   //    REACHES OR EXCEEDS threshold. Idempotency is owned by CEAState::Halt
   //    (state-machine guards re-fire); using >= here protects against batch
   //    increments and warm-restart counter recovery scenarios per ADR-006
   //    "≥10 consecutive failures" contract literal.
   if(m_consecutive_failures >= JOURNAL_HALT_THRESHOLD && m_halt_sink != NULL)
     {
      m_halt_sink.Halt("journal_write_fail_sustained");
     }
  }

void CTradeJournal::ResetConsecutiveOnSuccess()
  {
   m_consecutive_failures = 0;
   if(m_state != NULL)
      m_state.ResetJournalConsecutive();
  }

void CTradeJournal::TrackLatency(ulong elapsed_us, const string &event_type)
  {
   //--- PRESERVED: existing 10-write overshoot ring + warn-emit (Finding 03.10)
   m_overshoot_window[m_overshoot_idx] = elapsed_us;
   m_overshoot_idx = (m_overshoot_idx + 1) % JOURNAL_OVERSHOOT_WINDOW;

   ulong threshold_us = (ulong)JOURNAL_WARN_LATENCY_MS * 1000;
   int overshoot_count = 0;
   for(int i = 0; i < JOURNAL_OVERSHOOT_WINDOW; i++)
      if(m_overshoot_window[i] > threshold_us)
         overshoot_count++;

   if(overshoot_count >= 2 && m_logger != NULL)
      m_logger.Warn("system", "journal_write_slow", 0,
                    StringFormat("path=%s overshoots=%d/%d latest_ms=%llu threshold_ms=%d",
                                 m_active_path, overshoot_count, JOURNAL_OVERSHOOT_WINDOW,
                                 elapsed_us / 1000, JOURNAL_WARN_LATENCY_MS));

   //--- IMPL-066: running aggregates for NFR-2.2 ≥200-sample measurement
   m_latency_count++;
   m_latency_total_us += elapsed_us;
   if(elapsed_us > m_latency_max_us)
      m_latency_max_us = elapsed_us;

   //--- ring buffer of last 200 samples (for p95 estimation via sort)
   m_latency_samples[m_latency_samples_idx] = elapsed_us;
   m_latency_samples_idx = (m_latency_samples_idx + 1) % 200;
   if(m_latency_samples_filled < 200)
      m_latency_samples_filled++;

   //--- per-event-type linear-probe map (max 16 buckets; overflow → "_overflow")
   string key = (StringLen(event_type) > 0) ? event_type : "unknown";
   int bucket = -1;
   for(int i = 0; i < m_evtype_used; i++)
     {
      if(m_evtype_keys[i] == key)
        {
         bucket = i;
         break;
        }
     }
   if(bucket < 0)
     {
      //--- fix-round-17 § 17.5 — reserve bucket 15 for "_overflow"; populate
      //    unique event_types into buckets 0..14 only. On first overflow,
      //    initialise the overflow bucket cleanly (zero counters) and emit
      //    one-time Warn so operator knows attribution drifted.
      if(m_evtype_used < 15)
        {
         bucket = m_evtype_used;
         m_evtype_keys[bucket] = key;
         m_evtype_used++;
        }
      else
        {
         if(m_evtype_keys[15] != "_overflow")
           {
            if(m_logger != NULL)
               m_logger.Warn("system", "journal_evtype_overflow", 0,
                             StringFormat("event_type=%s does not fit; using _overflow bucket. "
                                          "Bump JOURNAL_EVTYPE_BUCKETS or audit event_type taxonomy.",
                                          key));
            m_evtype_keys[15]     = "_overflow";
            m_evtype_counts[15]   = 0;
            m_evtype_total_us[15] = 0;
           }
         bucket = 15;
        }
     }
   m_evtype_counts[bucket]++;
   m_evtype_total_us[bucket] += elapsed_us;

   //--- IMPL-066: periodic checkpoint every 1000 writes (trigger 1 of 2).
   //    fix-round-17 § 17.4 — Logger-only (no sidecar I/O on hot-path).
   if(m_latency_count % 1000 == 0)
      EmitLatencyReport(false);
  }

//+------------------------------------------------------------------+
//| EmitLatencyReport — IMPL-066 NFR-2.2 summary emit               |
//|                                                                   |
//| Triggers: (1) every 1000th write (periodic, inside TrackLatency)  |
//|           (2) final at Close() (complete session aggregate)       |
//| Outputs:  Logger Info lines + sidecar latency-report-<ISO>.json  |
//| NULL-guard: skips silently if m_logger == NULL or count == 0.     |
//+------------------------------------------------------------------+
void CTradeJournal::EmitLatencyReport(bool emit_sidecar)
  {
   if(m_latency_count == 0)
      return;

   //--- compute avg
   ulong avg_us = m_latency_total_us / (ulong)m_latency_count;

   //--- compute p95 via local copy + sort
   ulong local_samples[];
   int n = m_latency_samples_filled;
   ArrayResize(local_samples, n);
   for(int i = 0; i < n; i++)
      local_samples[i] = m_latency_samples[i];
   ArraySort(local_samples);
   int p95_idx = (int)(0.95 * n);
   if(p95_idx >= n)
      p95_idx = n - 1;
   ulong p95_us = (n > 0) ? local_samples[p95_idx] : 0;

   //--- emit summary Logger line
   if(m_logger != NULL)
     {
      m_logger.Info("system", "journal_latency_report", 0,
                    StringFormat("writes=%d avg_us=%llu p95_us=%llu max_us=%llu",
                                 m_latency_count, avg_us, p95_us, m_latency_max_us));

      //--- per-event-type rows
      for(int i = 0; i < m_evtype_used; i++)
        {
         ulong type_avg = (m_evtype_counts[i] > 0)
                          ? (m_evtype_total_us[i] / (ulong)m_evtype_counts[i])
                          : 0;
         m_logger.Info("system", "journal_latency_by_type", 0,
                       StringFormat("ev=%s writes=%d avg_us=%llu",
                                    m_evtype_keys[i], m_evtype_counts[i], type_avg));
        }
     }

   //--- sidecar JSON report (fix-round-17 § 17.4 — gated to final emit only)
   if(emit_sidecar && EnsureDirectories())
     {
      //--- build ISO timestamp for filename
      datetime now_s = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now_s, dt);
      string iso_tag = StringFormat("%04d%02d%02d-%02d%02d%02d",
                                    dt.year, dt.mon, dt.day,
                                    dt.hour, dt.min, dt.sec);
      string dir  = m_is_tester ? TesterDirectory() : LiveDirectory();
      string path = dir + "/latency-report-" + iso_tag + ".json";

      //--- build JSON body
      CJsonWriter w;
      w.Begin();
      w.WriteInt("writes",   m_latency_count);
      w.WriteInt("avg_us",   (long)avg_us);
      w.WriteInt("p95_us",   (long)p95_us);
      w.WriteInt("max_us",   (long)m_latency_max_us);
      w.WriteInt("sample_n", m_latency_samples_filled);

      //--- per-event-type array
      string types_json = "[";
      for(int i = 0; i < m_evtype_used; i++)
        {
         ulong type_avg = (m_evtype_counts[i] > 0)
                          ? (m_evtype_total_us[i] / (ulong)m_evtype_counts[i])
                          : 0;
         if(i > 0)
            types_json += ",";
         types_json += StringFormat("{\"event_type\":\"%s\",\"writes\":%d,\"avg_us\":%llu}",
                                    m_evtype_keys[i], m_evtype_counts[i], type_avg);
        }
      types_json += "]";
      w.WriteRaw("by_event_type", types_json);
      w.End();

      int fh = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(fh != INVALID_HANDLE)
        {
         FileWriteString(fh, w.ToString());
         FileClose(fh);
        }
      else if(m_logger != NULL)
        {
         m_logger.Warn("system", "journal_latency_report_write_fail", 0,
                       StringFormat("path=%s err=%d", path, GetLastError()));
        }
     }
  }

//+------------------------------------------------------------------+
//| Path helpers                                                     |
//+------------------------------------------------------------------+
string CTradeJournal::LiveDirectory() const
  {
   return "PhoenicisNex/journal/live";
  }

string CTradeJournal::TesterDirectory() const
  {
   return "PhoenicisNex/journal/tester";
  }

bool CTradeJournal::EnsureDirectories() const
  {
   string dirs[3];
   dirs[0] = "PhoenicisNex";
   dirs[1] = "PhoenicisNex/journal";
   dirs[2] = m_is_tester ? TesterDirectory() : LiveDirectory();

   for(int i = 0; i < 3; i++)
     {
      ResetLastError();
      if(!FolderCreate(dirs[i]))
        {
         int err = GetLastError();
         if(err != 0)
           {
            if(m_logger != NULL)
               m_logger.Error("system", "journal_mkdir_fail", 0,
                              StringFormat("dir=%s err=%d", dirs[i], err));
            return false;
           }
         // err==0 + false return == directory already exists; continue
        }
     }
   return true;
  }

string CTradeJournal::MonthlyKey(datetime now_s) const
  {
   MqlDateTime dt;
   TimeToStruct(now_s, dt);
   return StringFormat("%04d%02d", dt.year, dt.mon);
  }

string CTradeJournal::BuildLivePath(datetime now_s) const
  {
   return LiveDirectory() + "/journal-" + MonthlyKey(now_s) + ".jsonl";
  }

string CTradeJournal::BuildTesterRunId(datetime now_s, ulong micro) const
  {
   MqlDateTime dt;
   TimeToStruct(now_s, dt);
   ulong ms_within_sec = (micro / 1000) % 1000;
   return StringFormat("run-%04d%02d%02d-%02d%02d%02d-%03llu",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec, ms_within_sec);
  }

string CTradeJournal::BuildTesterPath() const
  {
   return TesterDirectory() + "/" + m_run_id + ".jsonl";
  }

#endif // PHOENICISNEX_SERVICES_TRADEJOURNAL_MQH
