"""
Orchestrator: find and process next pending monthly bar partition.

Usage:
  python -m src.orchestration.process_next_partition --config workshop/project/config/config.json
Options:
  --max <N>    number of partitions to process in one run (default from config.scheduler.max_partitions_per_run)
"""
import argparse
import json
import os
import sqlite3
import duckdb
import subprocess
from datetime import datetime


def load_config(path: str) -> dict:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def ensure_schema(db_path: str):
    ensure_dir(os.path.dirname(db_path))
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    with open('workshop/project/sql/schema.sql', 'r', encoding='utf-8') as f:
        cur.executescript(f.read())
    con.commit()
    con.close()


def discover_months(parquet_dir: str):
    conn = duckdb.connect()
    rows = conn.execute(
        f"""
        SELECT DISTINCT CAST(strftime(ts,'%Y') AS INTEGER) AS y,
                        CAST(strftime(ts,'%m') AS INTEGER) AS m
        FROM read_parquet('{os.path.join(parquet_dir, 'bars', 'bars.parquet')}')
        ORDER BY y, m
        """
    ).fetchall()
    conn.close()
    return [(int(y), int(m)) for (y, m) in rows]


def seed_partitions(db_path: str, symbol: str, timeframe: str, months: list):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    for (y, m) in months:
        cur.execute(
            """
            INSERT OR IGNORE INTO partitions_progress (
              symbol, timeframe, year, month, kind, status, last_offset, last_processed_at
            ) VALUES (?, ?, ?, ?, 'bars', 'pending', NULL, NULL)
            """,
            (symbol, timeframe, y, m)
        )
    con.commit()
    con.close()


def pick_next_pending(db_path: str, symbol: str, timeframe: str, limit: int):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute(
        """
        SELECT year, month FROM partitions_progress
        WHERE symbol=? AND timeframe=? AND kind='bars' AND status='pending'
        ORDER BY year, month
        LIMIT ?
        """,
        (symbol, timeframe, limit)
    )
    rows = cur.fetchall()
    con.close()
    return [(int(y), int(m)) for (y, m) in rows]


def mark_status(db_path: str, symbol: str, timeframe: str, y: int, m: int, status: str):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute(
        """
        UPDATE partitions_progress
        SET status=?, last_processed_at=?
        WHERE symbol=? AND timeframe=? AND kind='bars' AND year=? AND month=?
        """,
        (status, datetime.utcnow().isoformat(), symbol, timeframe, y, m)
    )
    con.commit()
    con.close()


def run_analyzer(config_path: str, timeframe: str, y: int, m: int) -> int:
    cmd = [
        os.sys.executable,
        '-m', 'src.analysis.analyze_patterns',
        '--config', config_path,
        '--year', str(y),
        '--month', str(m),
        '--timeframe', timeframe,
    ]
    print(f"[ORCH] Running: {' '.join(cmd)}")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    print(proc.stdout)
    if proc.returncode != 0:
        print(proc.stderr)
    return proc.returncode


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--max', type=int, default=None)
    args = parser.parse_args()

    cfg = load_config(args.config)
    parquet_dir = cfg.get('parquet_dir', 'workshop/parquet')
    db_path = cfg.get('sqlite_db', 'workshop/project/results.db')
    symbol = cfg.get('symbol', 'EURUSD')
    timeframe = cfg.get('timeframes', ['M1'])[0]
    max_per_run = args.max if args.max is not None else cfg.get('scheduler', {}).get('max_partitions_per_run', 4)

    ensure_schema(db_path)
    months = discover_months(parquet_dir)
    if not months:
        print('[ORCH] No months discovered in Parquet bars dataset. Run ETL first.')
        return

    seed_partitions(db_path, symbol, timeframe, months)
    to_process = pick_next_pending(db_path, symbol, timeframe, max_per_run)
    if not to_process:
        print('[ORCH] No pending partitions to process.')
        return

    for (y, m) in to_process:
        mark_status(db_path, symbol, timeframe, y, m, 'processing')
        rc = run_analyzer(args.config, timeframe, y, m)
        mark_status(db_path, symbol, timeframe, y, m, 'done' if rc == 0 else 'error')

    print('[ORCH] Completed run.')


if __name__ == '__main__':
    main()
