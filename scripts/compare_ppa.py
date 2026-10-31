#!/usr/bin/env python3
"""Summarize *recorded* ORFS post-route JSON metrics; do not infer run provenance.

Usage:
    python3 scripts/compare_ppa.py
    python3 scripts/compare_ppa.py --all --format csv
    python3 scripts/compare_ppa.py --run final_5ns --run exp_arith_tree_ks
"""
import argparse
import csv
import io
import json
from pathlib import Path
import sys

DEFAULT_RUNS = ["5ns", "final_5ns", "exp_arith_tree", "exp_arith_tree_ks"]
COLS = [
    ("setup_wns_ns", "setup_WNS_ns"),
    ("setup_tns_ns", "setup_TNS_ns"),
    ("hold_wns_ns", "hold_WNS_ns"),
    ("hold_tns_ns", "hold_TNS_ns"),
    ("stdcell_area_um2", "stdcell_area_um2"),
    ("max_cap_violations", "max_cap_viol"),
    ("macro_count", "macros"),
    ("power_est_mw", "power_est_mW"),
]
K = {
    "setup_wns_ns": "finish__timing__setup__ws",
    "setup_tns_ns": "finish__timing__setup__tns",
    "hold_wns_ns": "finish__timing__hold__ws",
    "hold_tns_ns": "finish__timing__hold__tns",
    "stdcell_area_um2": "finish__design__instance__area__stdcell",
    "max_cap_violations": "finish__timing__drv__max_cap",
    "macro_count": "finish__design__instance__count__macros",
    "power_est_mw": "finish__power__total",
}


def extract(path: Path):
    obj = json.loads(path.read_text(encoding="utf-8"))
    d = {"run": path.parent.name}
    for name, source in K.items():
        value = obj.get(source)
        d[name] = value * 1000.0 if name == "power_est_mw" and value is not None else value
    wns = d["setup_wns_ns"]
    hns = d["hold_wns_ns"]
    stns = d["setup_tns_ns"]
    htns = d["hold_tns_ns"]
    d["timing_reported_closed"] = (
        None if any(v is None for v in (wns, hns, stns, htns))
        else wns >= 0 and hns >= 0 and stns >= 0 and htns >= 0
    )
    return d


def display(v, key):
    if v is None:
        return "N/A"
    if isinstance(v, bool):
        return "yes" if v else "no"
    if key in {"macro_count", "max_cap_violations"}:
        return str(int(v))
    if key in {"stdcell_area_um2", "power_est_mw"}:
        return f"{v:,.1f}"
    return f"{v:+.6f}"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1],
                    help="Repository root containing physical_design/ (default: inferred)")
    ap.add_argument("--run", action="append", default=[],
                    help="Select a run name (repeatable); default: four featured runs")
    ap.add_argument("--all", action="store_true",
                    help="Include every run with an existing 6_report.json")
    ap.add_argument("--format", choices=["markdown", "csv", "json"], default="markdown")
    args = ap.parse_args()

    base = args.root / "physical_design" / "logs" / "nangate45" / "mnist_npu"
    names = [p.name for p in sorted(base.iterdir()) if (p / "6_report.json").is_file()] if args.all and base.is_dir() else (args.run or DEFAULT_RUNS)
    rows = []
    missing = []
    for name in names:
        p = base / name / "6_report.json"
        if not p.is_file():
            missing.append(str(p))
            continue
        try:
            rows.append(extract(p))
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            print(f"Cannot read {p}: {exc}", file=sys.stderr)
            return 2

    if not rows:
        print("No report JSON files found.", file=sys.stderr)
        return 2
    if missing:
        print("Missing, skipped reports: " + ", ".join(missing), file=sys.stderr)

    fieldnames = ["run"] + [key for key, _ in COLS] + ["timing_reported_closed"]
    if args.format == "json":
        print(json.dumps(rows, indent=2, ensure_ascii=False))
    elif args.format == "csv":
        buffer = io.StringIO()
        writer = csv.DictWriter(buffer, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
        print(buffer.getvalue(), end="")
    else:
        headers = ["Run"] + [header for _, header in COLS] + ["reported_timing_closed"]
        print("| " + " | ".join(headers) + " |")
        print("| " + " | ".join("---" for _ in headers) + " |")
        for r in rows:
            vals = [r["run"]] + [display(r[key], key) for key, _ in COLS] + [display(r["timing_reported_closed"], "timing_reported_closed")]
            print("| " + " | ".join(vals) + " |")

    return 0


if __name__ == "__main__":
    sys.exit(main())
