"""
Generate summary CSV and HTML reports from SQLite results.

Usage:
  python -m src.report.generate_reports --config workshop/project/config/config.json
"""
import argparse
import json
import os
import sqlite3
import pandas as pd


def load_config(path: str) -> dict:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    args = parser.parse_args()

    cfg = load_config(args.config)
    db_path = cfg.get('sqlite_db', 'workshop/project/results.db')
    out_dir = os.path.join(os.path.dirname(db_path), 'reports')
    ensure_dir(out_dir)

    con = sqlite3.connect(db_path)
    summary = pd.read_sql_query('SELECT * FROM bars_monthly_summary ORDER BY year, month', con)
    counts = pd.read_sql_query('SELECT * FROM pattern_counts ORDER BY year, month, pattern', con)
    outcomes = pd.read_sql_query('SELECT * FROM pattern_outcomes ORDER BY year, month, pattern, n', con)
    con.close()

    # Write CSV
    summary.to_csv(os.path.join(out_dir, 'bars_monthly_summary.csv'), index=False)
    counts.to_csv(os.path.join(out_dir, 'pattern_counts.csv'), index=False)
    outcomes.to_csv(os.path.join(out_dir, 'pattern_outcomes.csv'), index=False)

    # Simple HTML report
    html_path = os.path.join(out_dir, 'index.html')
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write('<html><head><meta charset="utf-8"><title>Price Action Reports</title>'
                '<style>body{font-family:Segoe UI,Arial;padding:16px} table{border-collapse:collapse;width:100%;margin-bottom:24px} th,td{border:1px solid #ddd;padding:8px} th{background:#f0f0f0}</style>'
                '</head><body>')
        f.write('<h1>Bars Monthly Summary</h1>')
        f.write(summary.to_html(index=False))
        f.write('<h1>Pattern Counts</h1>')
        f.write(counts.to_html(index=False))
        f.write('<h1>Pattern Outcomes</h1>')
        f.write(outcomes.to_html(index=False))
        f.write('</body></html>')

    print(f"[REPORT] CSV + HTML generated in {out_dir}")


if __name__ == '__main__':
    main()
