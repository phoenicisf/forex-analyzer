-- SQLite schema for Price Action Analytics

-- Track processing progress per partition
CREATE TABLE IF NOT EXISTS partitions_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  kind TEXT NOT NULL,            -- 'bars' | 'ticks' | 'deals'
  status TEXT NOT NULL,          -- 'pending' | 'processing' | 'done' | 'error'
  last_offset INTEGER,
  last_processed_at TEXT,
  UNIQUE(symbol, timeframe, year, month, kind)
);

-- Monthly summary of bar stats
CREATE TABLE IF NOT EXISTS bars_monthly_summary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  start_ts TEXT,
  end_ts TEXT,
  total_bars INTEGER,
  avg_close REAL,
  avg_range_pips REAL,
  avg_spread REAL,
  avg_tickvol REAL,
  UNIQUE(symbol, timeframe, year, month)
);

-- Pattern counts per month
CREATE TABLE IF NOT EXISTS pattern_counts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  pattern TEXT NOT NULL,        -- inside, outside, pin_bull, pin_bear, engulf_bull, engulf_bear
  count INTEGER NOT NULL,
  UNIQUE(symbol, timeframe, year, month, pattern)
);

-- Outcomes aggregated per pattern and N-bars
CREATE TABLE IF NOT EXISTS pattern_outcomes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  pattern TEXT NOT NULL,
  n INTEGER NOT NULL,
  count INTEGER NOT NULL,
  win_rate REAL,
  mean_return REAL,             -- average return
  std_return REAL,
  direction_rule TEXT,          -- 'none' | 'bullish_up' | 'bearish_down'
  UNIQUE(symbol, timeframe, year, month, pattern, n, direction_rule)
);
