"""
Analyze Price Action patterns on Parquet partitions and write results to SQLite.

Usage (example):
  python -m src.analysis.analyze_patterns --config workshop/project/config/config.json --year 2025 --month 1 --timeframe M1

Dependencies: pandas, duckdb OR polars, sqlite3
"""
import argparse
import json
import os
import sqlite3
import duckdb
import math


def load_config(path: str) -> dict:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def mean(xs):
    return sum(xs) / len(xs) if xs else None


def stddev(xs):
    if not xs or len(xs) < 2:
        return None
    m = mean(xs)
    var = sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
    return math.sqrt(var)


def detect_patterns(df):
    # df columns: ts, open, high, low, close, tick_volume, spread
    patterns = []
    pin_body_max = 0.33
    wick_min = 0.6
    for i in range(1, len(df)):
        cur = df[i]
        prev = df[i - 1]
        rng = cur['high'] - cur['low']
        if rng <= 0:
            continue
        body = cur['close'] - cur['open']
        body_high = max(cur['open'], cur['close'])
        body_low = min(cur['open'], cur['close'])
        upper = abs(cur['high'] - body_high)
        lower = abs(body_low - cur['low'])
        body_ratio = abs(body) / rng
        upper_ratio = upper / rng
        lower_ratio = lower / rng

        # inside
        if cur['high'] <= prev['high'] and cur['low'] >= prev['low']:
            patterns.append(('inside', i))
        # outside
        if cur['high'] >= prev['high'] and cur['low'] <= prev['low']:
            patterns.append(('outside', i))
        # pin bull
        if body > 0 and body_ratio <= pin_body_max and lower_ratio >= wick_min:
            patterns.append(('pin_bull', i))
        # pin bear
        if body < 0 and body_ratio <= pin_body_max and upper_ratio >= wick_min:
            patterns.append(('pin_bear', i))
        # engulf bull
        if body > 0 and body_high >= max(prev['open'], prev['close']) and body_low <= min(prev['open'], prev['close']):
            patterns.append(('engulf_bull', i))
        # engulf bear
        if body < 0 and body_high >= max(prev['open'], prev['close']) and body_low <= min(prev['open'], prev['close']):
            patterns.append(('engulf_bear', i))
    return patterns


def compute_outcomes(df, signals, next_bars, direction_specific=False):
    outcomes = {}
    for pat in ['inside', 'outside', 'pin_bull', 'pin_bear', 'engulf_bull', 'engulf_bear']:
        idxs = [idx for p, idx in signals if p == pat]
        for n in next_bars:
            rets = []
            for j in idxs:
                if j + n < len(df):
                    r = (df[j + n]['close'] / df[j]['close']) - 1.0
                    rets.append(r)
            if not rets:
                outcomes[(pat, n, 'none')] = (0, None, None, None)
                continue
            count = len(rets)
            avg = mean(rets)
            sd = stddev(rets)
            if direction_specific:
                if pat in ('pin_bull', 'engulf_bull'):
                    wins = sum(1 for x in rets if x > 0) / count
                    outcomes[(pat, n, 'bullish_up')] = (count, wins, avg, sd)
                elif pat in ('pin_bear', 'engulf_bear'):
                    wins = sum(1 for x in rets if x < 0) / count
                    outcomes[(pat, n, 'bearish_down')] = (count, wins, avg, sd)
                else:
                    wins = sum(1 for x in rets if x > 0) / count
                    outcomes[(pat, n, 'none')] = (count, wins, avg, sd)
            else:
                wins = sum(1 for x in rets if x > 0) / count
                outcomes[(pat, n, 'none')] = (count, wins, avg, sd)
    return outcomes


def write_sqlite(db_path, symbol, timeframe, year, month, bars_stats, counts, outcomes):
    ensure_dir(os.path.dirname(db_path))
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # ensure tables exist
    with open('workshop/project/sql/schema.sql', 'r', encoding='utf-8') as f:
        cur.executescript(f.read())

    # bars summary
    cur.execute("""
        INSERT OR REPLACE INTO bars_monthly_summary (
          id, symbol, timeframe, year, month, start_ts, end_ts, total_bars, avg_close, avg_range_pips, avg_spread, avg_tickvol
        ) VALUES (
          (SELECT id FROM bars_monthly_summary WHERE symbol=? AND timeframe=? AND year=? AND month=?),
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
    """, (
        symbol, timeframe, year, month,
        symbol, timeframe, year, month,
        bars_stats['start_ts'], bars_stats['end_ts'], bars_stats['total_bars'], bars_stats['avg_close'], bars_stats['avg_range_pips'], bars_stats['avg_spread'], bars_stats['avg_tickvol']
    ))

    # pattern counts
    for pat, cnt in counts.items():
        cur.execute("""
            INSERT OR REPLACE INTO pattern_counts (
              id, symbol, timeframe, year, month, pattern, count
            ) VALUES (
              (SELECT id FROM pattern_counts WHERE symbol=? AND timeframe=? AND year=? AND month=? AND pattern=?),
              ?, ?, ?, ?, ?, ?
            )
        """, (symbol, timeframe, year, month, pat, symbol, timeframe, year, month, pat, cnt))

    # outcomes
    for (pat, n, direction_rule), (count, win_rate, mean_return, std_return) in outcomes.items():
        cur.execute("""
            INSERT OR REPLACE INTO pattern_outcomes (
              id, symbol, timeframe, year, month, pattern, n, count, win_rate, mean_return, std_return, direction_rule
            ) VALUES (
              (SELECT id FROM pattern_outcomes WHERE symbol=? AND timeframe=? AND year=? AND month=? AND pattern=? AND n=? AND direction_rule=?),
              ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
        """, (
            symbol, timeframe, year, month, pat, n, direction_rule,
            symbol, timeframe, year, month, pat, n, count, win_rate, mean_return, std_return, direction_rule
        ))

    con.commit()
    con.close()


def read_month_bars(conn: duckdb.DuckDBPyConnection, parquet_dir: str, year: int, month: int):
    path = os.path.join(parquet_dir, 'bars')
    # Expect DuckDB to read partitioned dataset
    df = conn.execute(
        f"""
        SELECT ts, CAST(open AS DOUBLE) AS open, CAST(high AS DOUBLE) AS high,
               CAST(low AS DOUBLE) AS low, CAST(close AS DOUBLE) AS close,
               CAST(TickVolume AS BIGINT) AS tick_volume,
               CAST(Spread AS DOUBLE) AS spread
        FROM read_parquet('{path}/bars.parquet')
        WHERE strftime(ts, '%Y') = '{year:04d}' AND strftime(ts, '%m') = '{month:02d}'
        ORDER BY ts
        """
    ).fetchall()
    # convert to list of dicts
    cols = ['ts','open','high','low','close','tick_volume','spread']
    return [dict(zip(cols, row)) for row in df]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--year', type=int, required=True)
    parser.add_argument('--month', type=int, required=True)
    parser.add_argument('--timeframe', default='M1')
    args = parser.parse_args()

    cfg = load_config(args.config)
    parquet_dir = cfg.get('parquet_dir', 'workshop/parquet')
    db_path = cfg.get('sqlite_db', 'workshop/project/results.db')
    symbol = cfg.get('symbol', 'EURUSD')
    next_bars = cfg.get('analyzer', {}).get('next_bars', [1,3,5])
    direction_specific = cfg.get('analyzer', {}).get('direction_specific', False)

    conn = duckdb.connect()
    bars = read_month_bars(conn, parquet_dir, args.year, args.month)
    conn.close()

    if not bars:
        print(f"[WARN] No bars for {args.year}-{args.month:02d}")
        return

    signals = detect_patterns(bars)

    # basic stats
    total = len(bars)
    start_ts = bars[0]['ts']
    end_ts = bars[-1]['ts']
    avg_close = mean([x['close'] for x in bars])
    avg_range_pips = mean([(x['high'] - x['low']) * 10000 for x in bars])
    avg_spread = mean([x['spread'] for x in bars])
    avg_tickvol = mean([x['tick_volume'] for x in bars])
    bars_stats = {
        'total_bars': total,
        'start_ts': str(start_ts),
        'end_ts': str(end_ts),
        'avg_close': avg_close,
        'avg_range_pips': avg_range_pips,
        'avg_spread': avg_spread,
        'avg_tickvol': avg_tickvol,
    }

    # counts
    counts = {}
    for p in ['inside','outside','pin_bull','pin_bear','engulf_bull','engulf_bear']:
        counts[p] = sum(1 for (pat, _) in signals if pat == p)

    # outcomes
    outcomes = compute_outcomes(bars, signals, next_bars, direction_specific=direction_specific)

    # write to sqlite
    ensure_dir(os.path.dirname(db_path))
    write_sqlite(db_path, symbol, args.timeframe, args.year, args.month, bars_stats, counts, outcomes)
    print(f"[OK] Wrote results to {db_path} for {symbol} {args.timeframe} {args.year}-{args.month:02d}")


if __name__ == '__main__':
    main()
