"""
ETL: Convert large CSV exports from MT5 into time-partitioned Parquet files.
- Bars & Deals: monthly partitions
- Ticks: daily partitions (or hourly, if needed)

Usage (example):
  python -m src.etl.ingest_csv_to_parquet --config workshop/project/config/config.json --kind bars

Dependencies: duckdb, pyarrow
"""
import argparse
import json
import os
import sys
import duckdb
from datetime import datetime


def load_config(path: str) -> dict:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def ingest_bars(conn: duckdb.DuckDBPyConnection, data_dir: str, parquet_dir: str, pattern: str):
    print(f"[ETL] Ingest Bars from {data_dir}/{pattern} -> Parquet monthly in {parquet_dir}")
    ensure_dir(parquet_dir)
    sql = f"""
        INSTALL parquet; LOAD parquet;
        SET enable_object_cache = true;
        CREATE TEMP TABLE bars AS
        SELECT * FROM read_csv_auto('{os.path.join(data_dir, pattern)}', header=true);
    """
    conn.execute(sql)

    # Expect columns: Date, Time, Open, High, Low, Close, TickVolume, Spread, RealVolume
    # Build timestamp and write monthly partitions
    conn.execute(
        """
        ALTER TABLE bars ADD COLUMN ts TIMESTAMP;
        UPDATE bars SET ts = strptime(Date || ' ' || Time, '%Y.%m.%d %H:%M');
        CREATE TABLE bars_sorted AS SELECT * FROM bars WHERE ts IS NOT NULL ORDER BY ts;
    """
    )

    # Write monthly partitioned Parquet
    out_base = os.path.join(parquet_dir, 'bars')
    ensure_dir(out_base)
    conn.execute(
        f"""
        COPY (
            SELECT * FROM bars_sorted
        ) TO '{out_base}/bars.parquet' (FORMAT PARQUET, PARTITION_BY (strftime(ts, '%Y'), strftime(ts, '%m')));
        """
    )
    print("[ETL] Bars -> Parquet (monthly) done.")


def ingest_ticks(conn: duckdb.DuckDBPyConnection, data_dir: str, parquet_dir: str, pattern: str):
    print(f"[ETL] Ingest Ticks from {data_dir}/{pattern} -> Parquet daily in {parquet_dir}")
    ensure_dir(parquet_dir)
    sql = f"""
        INSTALL parquet; LOAD parquet;
        SET enable_object_cache = true;
        CREATE TEMP TABLE ticks AS
        SELECT * FROM read_csv_auto('{os.path.join(data_dir, pattern)}', header=true);
    """
    conn.execute(sql)

    conn.execute(
        """
        ALTER TABLE ticks ADD COLUMN ts TIMESTAMP;
        UPDATE ticks SET ts = strptime(Date || ' ' || Time, '%Y.%m.%d %H:%M:%S');
        CREATE TABLE ticks_sorted AS SELECT * FROM ticks WHERE ts IS NOT NULL ORDER BY ts;
    """
    )

    out_base = os.path.join(parquet_dir, 'ticks')
    ensure_dir(out_base)
    conn.execute(
        f"""
        COPY (
            SELECT * FROM ticks_sorted
        ) TO '{out_base}/ticks.parquet' (FORMAT PARQUET, PARTITION_BY (strftime(ts, '%Y'), strftime(ts, '%m'), strftime(ts, '%d')));
        """
    )
    print("[ETL] Ticks -> Parquet (daily) done.")


def ingest_deals(conn: duckdb.DuckDBPyConnection, data_dir: str, parquet_dir: str, pattern: str):
    print(f"[ETL] Ingest Deals from {data_dir}/{pattern} -> Parquet monthly in {parquet_dir}")
    ensure_dir(parquet_dir)
    sql = f"""
        INSTALL parquet; LOAD parquet;
        SET enable_object_cache = true;
        CREATE TEMP TABLE deals AS
        SELECT * FROM read_csv_auto('{os.path.join(data_dir, pattern)}', header=true);
    """
    conn.execute(sql)

    conn.execute(
        """
        ALTER TABLE deals ADD COLUMN ts TIMESTAMP;
        UPDATE deals SET ts = strptime(Date || ' ' || Time, '%Y.%m.%d %H:%M:%S');
        CREATE TABLE deals_sorted AS SELECT * FROM deals WHERE ts IS NOT NULL ORDER BY ts;
    """
    )

    out_base = os.path.join(parquet_dir, 'deals')
    ensure_dir(out_base)
    conn.execute(
        f"""
        COPY (
            SELECT * FROM deals_sorted
        ) TO '{out_base}/deals.parquet' (FORMAT PARQUET, PARTITION_BY (strftime(ts, '%Y'), strftime(ts, '%m')));
        """
    )
    print("[ETL] Deals -> Parquet (monthly) done.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--kind', required=True, choices=['bars', 'ticks', 'deals'])
    args = parser.parse_args()

    cfg = load_config(args.config)
    data_dir = cfg.get('data_dir', 'MQL5/Files')
    parquet_dir = cfg.get('parquet_dir', 'workshop/parquet')
    bars_pattern = cfg.get('bars_csv_pattern', 'EURUSD_BARS_*.csv')
    ticks_pattern = cfg.get('ticks_csv_pattern', 'EURUSD_TICKS_*.csv')
    deals_pattern = cfg.get('deals_csv_pattern', 'EURUSD_DEALS_*.csv')

    ensure_dir(parquet_dir)
    conn = duckdb.connect()

    if args.kind == 'bars':
        ingest_bars(conn, data_dir, parquet_dir, bars_pattern)
    elif args.kind == 'ticks':
        ingest_ticks(conn, data_dir, parquet_dir, ticks_pattern)
    elif args.kind == 'deals':
        ingest_deals(conn, data_dir, parquet_dir, deals_pattern)

    conn.close()


if __name__ == '__main__':
    main()
