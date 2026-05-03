//+------------------------------------------------------------------+
//| TimeGate.mqh — Time-based trading gate filters (IMPL-050)        |
//| Layer:   services/ — Orchestrator injects via Init()             |
//| Source:  TD-02 §5.9, BR-3.1/3.2/3.3/3.4/3.7, FR-6.5, NFR-7.3  |
//|          Claim 01.18 (ban allowlist), ADR-007 (state.json atomic)|
//|                                                                  |
//| DST handling:                                                    |
//|   All time checks use TimeCurrent() which returns broker server  |
//|   time (EET = GMT+2 winter / GMT+3 summer DST).                 |
//|   Relying on broker-native server time means DST transitions     |
//|   (last Sunday March → +1h; last Sunday October → -1h) are      |
//|   transparent: FR-6.5 + NFR-7.3. DO NOT call TimeGMT() /        |
//|   TimeLocal() — those strip broker DST context.                  |
//|   DST transition example: 2021-03-28 00:00 GMT+2 → 03:00 GMT+3  |
//|   TimeCurrent() reflects this natively; no manual offset needed. |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_TIMEGATE_MQH
#define PHOENICISNEX_SERVICES_TIMEGATE_MQH

#include "Logger.mqh"
#include "StatePersistence.mqh"
#include "PortfolioState.mqh"
#include "../helpers/PipMath.mqh"

//+------------------------------------------------------------------+
//| CTimeGate — mirrors TD-02 §5.9 skeleton verbatim                 |
//|                                                                  |
//| Allowlist (Claim 01.18): ban operations restricted to slots      |
//|   {C, L, M, K, G}. Unknown slot → Error log + early return.     |
//|                                                                  |
//| Cooldown bar counts come from Init() params (no hardcoding per   |
//| IMPL-050 constraint). Defaults match Inputs_TimeGates.mqh.       |
//+------------------------------------------------------------------+
class CTimeGate
  {
private:
   //--- Configuration (set via Init; defaults match Inputs_TimeGates.mqh)
   int               m_morning_window_minutes;   // BR-3.1 — default 5 (00:00-00:05 broker)
   int               m_monday_spread_threshold;  // BR-3.2/BR-3.7 — default 10 spread points
   int               m_holiday_start_month;      // BR-3.3 — default 12 (December)
   int               m_holiday_start_day;        // default 21
   int               m_holiday_end_month;        // default 1 (January)
   int               m_holiday_end_day;          // default 3

   //--- Per-slot ban cooldown bars (BR-3.4; values from Init params)
   int               m_ban_c_cooldown_bars;          // default 5 H4 bars after C close-loss
   int               m_ban_l_cooldown_bars;          // default 5
   int               m_ban_m_cooldown_bars;          // default 5
   int               m_k_last_order_cooldown_bars;   // default 4
   int               m_g_pause_cooldown_bars;        // default 3

   //--- Injected dependencies (Composition Root per ADR-002)
   CPipMath          *m_pip;
   CStatePersistence *m_state;
   CLogger           *m_logger;

   //--- Map slot_id to ban_field key used by CStatePersistence (Claim 01.18)
   //    Returns "" for non-allowlist slots
   string            _BanFieldForSlot(string slot_id) const;

   //--- Get cooldown seconds for slot (H4 bar = 4 * 3600 seconds)
   int               _CooldownSecondsForSlot(string slot_id) const;

   //--- Private allowlist check — consistent with public IsBanAllowedSlot
   bool              IsBanAllowedSlot(string slot_id) const
     {
      return slot_id == "C" || slot_id == "L" || slot_id == "M" ||
             slot_id == "K" || slot_id == "G";
     }

public:
   //--- Constructor — zero-init; Init() must be called before any method
   CTimeGate()
      : m_morning_window_minutes(5),
        m_monday_spread_threshold(10),
        m_holiday_start_month(12),
        m_holiday_start_day(21),
        m_holiday_end_month(1),
        m_holiday_end_day(3),
        m_ban_c_cooldown_bars(5),
        m_ban_l_cooldown_bars(5),
        m_ban_m_cooldown_bars(5),
        m_k_last_order_cooldown_bars(4),
        m_g_pause_cooldown_bars(3),
        m_pip(NULL), m_state(NULL), m_logger(NULL)
     {}

   //--- Init — store all params and dependency pointers
   //    Called at Orchestrator OnInit Phase C (TD-02 §7.4) after Logger +
   //    StatePersistence + PortfolioState are wired (Composition Root).
   void Init(int morning_window_minutes,
             int monday_spread_threshold,
             int holiday_start_month,
             int holiday_start_day,
             int holiday_end_month,
             int holiday_end_day,
             int ban_c_cooldown_bars,
             int ban_l_cooldown_bars,
             int ban_m_cooldown_bars,
             int k_last_order_cooldown_bars,
             int g_pause_cooldown_bars,
             CPipMath *pip,
             CStatePersistence *state,
             CLogger *logger);

   //--- BR-3.1: IsMorningWakeup — true during [00:00, 00:00+window) broker server time
   //    Uses TimeCurrent() (broker EET DST-native, per FR-6.5 + NFR-7.3)
   //    Returns true if hour == 0 AND minute < m_morning_window_minutes
   bool IsMorningWakeup(datetime server_now) const;

   //--- BR-3.2 / BR-3.7: IsMondaySpreadHigh — true when Monday AND spread high
   //    Returns true iff DayOfWeek == Monday AND spread_points > threshold
   //    Note: spread_points passed in by caller (from MarketContext snapshot)
   bool IsMondaySpreadHigh(datetime server_now, int spread_points) const;

   //--- BR-3.3: IsNewYearSeason2 — true during holiday season window
   //    Window: holiday_start_month/day .. holiday_end_month/day (cross-year safe)
   //    HolidayBlock supersedes this for most callers — this is the primitive
   bool IsNewYearSeason2(datetime server_now) const;

   //--- BR-3.3: HolidayBlock — true when holiday AND CD-count gate satisfied
   //    Accepts CPortfolioState& to read active CD position count (BR-3.3 gate)
   //    Returns true (block new entries) when holiday season active AND
   //    net CD open position count > 0 (existing positions wind down only)
   bool HolidayBlock(datetime server_now, CPortfolioState &port) const;

   //--- BR-3.4: IsBanned — check if slot is currently under cooldown ban
   //    Allowlist {C, L, M, K, G} per Claim 01.18.
   //    Unknown slot → Error log + return false (safe: not banned = allow trade)
   bool IsBanned(string slot_id, datetime server_now) const;

   //--- BR-3.4: SetBan — record ban start; compute end = now + cooldown bars × H4
   //    Writes ban end-date to state.json § ban_dates via CStatePersistence.SetBanDate
   //    Allowlist {C, L, M, K, G} per Claim 01.18.
   //    Unknown slot → Error log + early return (no state write)
   void SetBan(string slot_id, datetime server_now);

  }; // end class CTimeGate

//+------------------------------------------------------------------+
//| Init — store params + dep pointers; log init_ok on success       |
//+------------------------------------------------------------------+
void CTimeGate::Init(int morning_window_minutes,
                     int monday_spread_threshold,
                     int holiday_start_month,
                     int holiday_start_day,
                     int holiday_end_month,
                     int holiday_end_day,
                     int ban_c_cooldown_bars,
                     int ban_l_cooldown_bars,
                     int ban_m_cooldown_bars,
                     int k_last_order_cooldown_bars,
                     int g_pause_cooldown_bars,
                     CPipMath *pip,
                     CStatePersistence *state,
                     CLogger *logger)
  {
   m_morning_window_minutes     = morning_window_minutes;
   m_monday_spread_threshold    = monday_spread_threshold;
   m_holiday_start_month        = holiday_start_month;
   m_holiday_start_day          = holiday_start_day;
   m_holiday_end_month          = holiday_end_month;
   m_holiday_end_day            = holiday_end_day;
   m_ban_c_cooldown_bars        = ban_c_cooldown_bars;
   m_ban_l_cooldown_bars        = ban_l_cooldown_bars;
   m_ban_m_cooldown_bars        = ban_m_cooldown_bars;
   m_k_last_order_cooldown_bars = k_last_order_cooldown_bars;
   m_g_pause_cooldown_bars      = g_pause_cooldown_bars;
   m_pip    = pip;
   m_state  = state;
   m_logger = logger;

   if(m_logger != NULL)
      m_logger.Info("TimeGate", "init_ok", 0,
                    StringFormat("window=%d spread_thr=%d holiday=%d/%d..%d/%d",
                                 m_morning_window_minutes,
                                 m_monday_spread_threshold,
                                 m_holiday_start_month, m_holiday_start_day,
                                 m_holiday_end_month,   m_holiday_end_day));
  }

//+------------------------------------------------------------------+
//| _BanFieldForSlot — map slot_id to state.json ban_dates key       |
//| Returns "" for non-allowlist slots (caller checks).              |
//+------------------------------------------------------------------+
string CTimeGate::_BanFieldForSlot(string slot_id) const
  {
   if(slot_id == "C") return "ban_c";
   if(slot_id == "L") return "ban_l";
   if(slot_id == "M") return "ban_m";
   if(slot_id == "K") return "k_last_order";
   if(slot_id == "G") return "g_pause";
   return "";
  }

//+------------------------------------------------------------------+
//| _CooldownSecondsForSlot — cooldown in seconds (bars × H4 secs)  |
//| H4 bar = 4 × 3600 = 14400 seconds.                              |
//+------------------------------------------------------------------+
int CTimeGate::_CooldownSecondsForSlot(string slot_id) const
  {
   //--- H4 period in seconds (MT5 PERIOD_H4 = 4 hours = 14400 seconds)
   const int H4_SECS = 4 * 3600;

   if(slot_id == "C") return m_ban_c_cooldown_bars        * H4_SECS;
   if(slot_id == "L") return m_ban_l_cooldown_bars        * H4_SECS;
   if(slot_id == "M") return m_ban_m_cooldown_bars        * H4_SECS;
   if(slot_id == "K") return m_k_last_order_cooldown_bars * H4_SECS;
   if(slot_id == "G") return m_g_pause_cooldown_bars      * H4_SECS;
   return 0;
  }

//+------------------------------------------------------------------+
//| IsMorningWakeup — BR-3.1                                         |
//| DST: uses broker server time (EET native, FR-6.5 + NFR-7.3)     |
//| Window: [00:00, 00:00 + m_morning_window_minutes) inclusive      |
//+------------------------------------------------------------------+
bool CTimeGate::IsMorningWakeup(datetime server_now) const
  {
   //--- Use TimeCurrent() caller already resolved; decompose server_now directly
   //    DST-transparent: broker EET time reflects DST; no manual GMT offset needed
   MqlDateTime dt;
   TimeToStruct(server_now, dt);

   //--- true iff hour == 0 AND minute < window
   return (dt.hour == 0 && dt.min < m_morning_window_minutes);
  }

//+------------------------------------------------------------------+
//| IsMondaySpreadHigh — BR-3.2 / BR-3.7                            |
//| Returns true ONLY when Monday AND spread_points > threshold      |
//| Day-of-week from broker server time (EET DST-native).           |
//+------------------------------------------------------------------+
bool CTimeGate::IsMondaySpreadHigh(datetime server_now, int spread_points) const
  {
   MqlDateTime dt;
   TimeToStruct(server_now, dt);

   //--- MQL5 day_of_week: 0=Sunday, 1=Monday, ..., 6=Saturday
   if(dt.day_of_week != 1) return false;                 // not Monday
   return spread_points > m_monday_spread_threshold;
  }

//+------------------------------------------------------------------+
//| IsNewYearSeason2 — BR-3.3                                        |
//| Holiday window crosses year boundary:                            |
//|   Dec m_holiday_start_day → Jan m_holiday_end_day               |
//| Logic: block if (month == start_month AND day >= start_day)      |
//|           OR  (month == end_month   AND day <= end_day)          |
//| Months between start and end (exclusive) also block when         |
//|   start_month > end_month (i.e., cross-year window).             |
//+------------------------------------------------------------------+
bool CTimeGate::IsNewYearSeason2(datetime server_now) const
  {
   MqlDateTime dt;
   TimeToStruct(server_now, dt);
   int month = dt.mon;
   int day   = dt.day;

   //--- Cross-year window: start_month > end_month (e.g., Dec > Jan)
   if(m_holiday_start_month > m_holiday_end_month)
     {
      //--- In the start month: on or after start_day
      if(month == m_holiday_start_month && day >= m_holiday_start_day) return true;
      //--- In the end month: on or before end_day
      if(month == m_holiday_end_month   && day <= m_holiday_end_day)   return true;
      //--- Any month between (e.g., month 13..12 wrap — months after start through Dec)
      if(month > m_holiday_start_month) return true;
      if(month < m_holiday_end_month)   return true;
      return false;
     }
   else
     {
      //--- Same-year window (start_month <= end_month)
      if(month < m_holiday_start_month || month > m_holiday_end_month) return false;
      if(month == m_holiday_start_month && day < m_holiday_start_day)  return false;
      if(month == m_holiday_end_month   && day > m_holiday_end_day)    return false;
      return true;
     }
  }

//+------------------------------------------------------------------+
//| HolidayBlock — BR-3.3 + CD-count gate                           |
//| Returns true (block new entries) when:                           |
//|   1. IsNewYearSeason2() is active, AND                           |
//|   2. CD slot has at least 1 open position (wind-down mode)       |
//| CPortfolioState& used to read CD position count (magic 200).    |
//+------------------------------------------------------------------+
bool CTimeGate::HolidayBlock(datetime server_now, CPortfolioState &port) const
  {
   if(!IsNewYearSeason2(server_now))
      return false;   // not holiday season — no block

   //--- CD-count gate per BR-3.3: block new entries only when CD positions active
   //    CD pool uses MagicCD = 200 (per domain glossary CLAUDE.md §7b)
   SlotState *cd_state = port.GetByMagic(200);
   if(cd_state == NULL)
     {
      //--- GetByMagic logs warn for unregistered magic; treat as no positions
      return true;   // holiday active, assume block (safe default)
     }

   int cd_total = cd_state.buy_count + cd_state.sell_count;
   //--- Block new entries if any CD position is open; allow if flat
   return (cd_total > 0);
  }

//+------------------------------------------------------------------+
//| IsBanned — BR-3.4 allowlist enforcement                          |
//| Unknown slot → Error log + return false (not banned = safe)     |
//| Returns true if ban_end_date > server_now (still in cooldown)   |
//+------------------------------------------------------------------+
bool CTimeGate::IsBanned(string slot_id, datetime server_now) const
  {
   //--- Claim 01.18 allowlist guard
   if(!IsBanAllowedSlot(slot_id))
     {
      if(m_logger != NULL)
         m_logger.Error("TimeGate", "ban_unknown_slot", 0,
                        StringFormat("slot=%s is not in ban allowlist {C,L,M,K,G} — ignored",
                                     slot_id));
      return false;   // unknown slot: do not block (fail-open on unknown is safe here)
     }

   if(m_state == NULL) return false;   // no state → cannot evaluate ban → allow

   string ban_field = _BanFieldForSlot(slot_id);
   datetime ban_end = m_state.GetBanDate(ban_field);

   return (ban_end > server_now);   // true = still banned
  }

//+------------------------------------------------------------------+
//| SetBan — BR-3.4 write ban to state.json § ban_dates             |
//| ban_end = server_now + cooldown_bars × H4_SECS                  |
//| Writes via CStatePersistence.SetBanDate (ADR-007 Option A flow  |
//| persists on next Save() call — no immediate file write here).   |
//| Unknown slot → Error log + early return (no state write).       |
//+------------------------------------------------------------------+
void CTimeGate::SetBan(string slot_id, datetime server_now)
  {
   //--- Claim 01.18 allowlist guard — no silent failure (NFR-3.4)
   if(!IsBanAllowedSlot(slot_id))
     {
      if(m_logger != NULL)
         m_logger.Error("TimeGate", "ban_unknown_slot", 0,
                        StringFormat("slot=%s is not in ban allowlist {C,L,M,K,G} — SetBan ignored",
                                     slot_id));
      return;
     }

   if(m_state == NULL)
     {
      if(m_logger != NULL)
         m_logger.Warn("TimeGate", "set_ban_no_state", 0,
                       StringFormat("slot=%s SetBan called but m_state is NULL — ban not persisted",
                                    slot_id));
      return;
     }

   int cooldown_secs = _CooldownSecondsForSlot(slot_id);
   datetime ban_end  = server_now + (datetime)cooldown_secs;
   string   ban_field = _BanFieldForSlot(slot_id);

   //--- Write to in-memory state (persisted to state.json on next Save() call)
   m_state.SetBanDate(ban_field, ban_end);

   if(m_logger != NULL)
      m_logger.Info("TimeGate", "ban_set", 0,
                    StringFormat("slot=%s ban_end=%s cooldown_secs=%d",
                                 slot_id,
                                 TimeToString(ban_end, TIME_DATE | TIME_MINUTES),
                                 cooldown_secs));
  }

#endif // PHOENICISNEX_SERVICES_TIMEGATE_MQH
