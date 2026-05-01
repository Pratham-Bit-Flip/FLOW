#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path

REQ_FIELDS = [
    "board",
    "toolchain",
    "lut_alm",
    "registers_ff",
    "block_rams",
    "dsp_blocks",
    "fmax_mhz",
    "total_power_w",
    "dynamic_power_w",
]


def _safe_float(v):
    try:
        return float(v)
    except Exception:
        return None


def _norm_metric(v):
    return "N/A" if v is None else v


def extract_from_nextpnr_report(report_path: Path):
    if not report_path.exists():
        return {}
    with report_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    out = {}

    fmax = None
    if isinstance(data.get("fmax"), dict):
        for _, v in data["fmax"].items():
            if isinstance(v, dict):
                cand = v.get("achieved") or v.get("fmax") or v.get("max")
                if cand is not None:
                    fmax = _safe_float(cand)
                    break
            elif isinstance(v, (int, float, str)):
                fmax = _safe_float(v)
                if fmax is not None:
                    break
    elif isinstance(data.get("fmax"), (int, float, str)):
        fmax = _safe_float(data.get("fmax"))

    out["fmax_mhz"] = fmax

    util = data.get("utilization", {}) if isinstance(data, dict) else {}
    if isinstance(util, dict):
        def pick(*keys):
            for k in keys:
                if k in util:
                    val = util[k]
                    if isinstance(val, dict):
                        for vv in (val.get("used"), val.get("count"), val.get("value")):
                            if vv is not None:
                                return vv
                    return val
            return None

        out["lut_alm"] = pick(
            "LUT", "LUT4", "LC", "SLICE_LUTS", "LUTs",
            "TRELLIS_COMB", "SLICE_LUTX"
        )
        out["registers_ff"] = pick(
            "DFF", "FF", "SLICE_REGISTERS", "Registers",
            "TRELLIS_FF", "SLICE_FFX"
        )
        out["block_rams"] = pick(
            "BRAM", "RAMB18", "RAMB36", "BlockRAM", "BRAMs",
            "DP16KD", "RAMB18E1_RAMB18E1", "RAMB36E1_RAMB36E1"
        )
        out["dsp_blocks"] = pick(
            "DSP", "DSP48", "DSP48E1", "DSPs",
            "MULT18X18D", "DSP48E1_DSP48E1"
        )

    return out


def main():
    ap = argparse.ArgumentParser(description="Extract OSS PPA metrics into CSV/Markdown")
    ap.add_argument("--board", required=True)
    ap.add_argument("--toolchain", required=True)
    ap.add_argument("--report-json", required=True)
    ap.add_argument("--csv", required=True)
    ap.add_argument("--md", required=True)
    args = ap.parse_args()

    report_path = Path(args.report_json)
    m = extract_from_nextpnr_report(report_path)

    row = {
        "board": args.board,
        "toolchain": args.toolchain,
        "lut_alm": _norm_metric(m.get("lut_alm")),
        "registers_ff": _norm_metric(m.get("registers_ff")),
        "block_rams": _norm_metric(m.get("block_rams")),
        "dsp_blocks": _norm_metric(m.get("dsp_blocks")),
        "fmax_mhz": _norm_metric(m.get("fmax_mhz")),
        "total_power_w": "N/A",
        "dynamic_power_w": "N/A",
    }

    csv_path = Path(args.csv)
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=REQ_FIELDS)
        w.writeheader()
        w.writerow(row)

    md_path = Path(args.md)
    md_path.parent.mkdir(parents=True, exist_ok=True)
    with md_path.open("w", encoding="utf-8") as f:
        f.write("| Metric | Value |\n")
        f.write("|---|---|\n")
        f.write(f"| Board | {row['board']} |\n")
        f.write(f"| Toolchain | {row['toolchain']} |\n")
        f.write(f"| LUTs/ALMs | {row['lut_alm']} |\n")
        f.write(f"| Registers/FFs | {row['registers_ff']} |\n")
        f.write(f"| Block RAMs | {row['block_rams']} |\n")
        f.write(f"| DSP Blocks | {row['dsp_blocks']} |\n")
        f.write(f"| Fmax (MHz) | {row['fmax_mhz']} |\n")
        f.write(f"| Total Power (W) | {row['total_power_w']} |\n")
        f.write(f"| Dynamic Power (W) | {row['dynamic_power_w']} |\n")

    print(f"Wrote: {csv_path}")
    print(f"Wrote: {md_path}")


if __name__ == "__main__":
    main()
