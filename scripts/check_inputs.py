#!/usr/bin/env python3
"""Check testbench input-vector completeness; never fabricate missing data."""
import argparse
from pathlib import Path
import sys


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data-dir", type=Path, default=Path("."),
                    help="Directory containing files expected by the simulation")
    ap.add_argument("--samples", type=int, choices=(100, 1000), default=100)
    args = ap.parse_args()

    base = args.data_dir
    if not base.is_dir():
        print(f"Missing directory: {base}", file=sys.stderr)
        return 2

    groups = {
        "weights": ["weights.hex"],
        "labels": ["labels.hex"],
        "images": [f"image_{i}.hex" for i in range(args.samples)],
        "FC1 golden": [f"fc1_expected_{i}.hex" for i in range(args.samples)],
        "FC2 golden": [f"fc2_expected_{i}.hex" for i in range(args.samples)],
    }
    absent_total = 0
    for label, paths in groups.items():
        missing = [p for p in paths if not (base / p).is_file()]
        absent_total += len(missing)
        print(f"{label:12} present={len(paths)-len(missing):4}/{len(paths):4} missing={len(missing):4}")
        if missing:
            preview = ", ".join(missing[:3])
            print(f"  e.g. {preview}" + (" ..." if len(missing) > 3 else ""))

    if absent_total:
        print(f"INCOMPLETE: {absent_total} required vector file(s) missing in {base}")
        return 1
    print("COMPLETE: all filenames expected by the testbench are present.")
    print("NOTE: presence is not validation of format, provenance, or numerical correctness.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
