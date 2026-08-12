#!/usr/bin/env python
"""Task D - Power BI data preparation.

Reads the master (read-only) BIA_CMB_Dataset.csv, validates it, derives the
Destination Country column (mirror of the guide's DAX), writes a clean copy to
07_Task_D_PowerBI_SKIPPED/cleaned_data/BIA_CMB_clean.csv and emits a profiling
report to outputs/data_profiling.md.

Original master in 03_Original_Datasets/ is NEVER modified.
"""
import csv
import io
import json
import math
import pathlib
import sys
from collections import Counter
from datetime import datetime

ROOT = pathlib.Path(__file__).resolve().parents[2]
MASTER = ROOT / "03_Original_Datasets" / "Task_D" / "BIA_CMB_Dataset.csv"
OUT_DIR = ROOT / "07_Task_D_PowerBI_SKIPPED"
CLEAN = OUT_DIR / "cleaned_data" / "BIA_CMB_clean.csv"
OUTPUTS = OUT_DIR / "outputs"
SCREENSHOTS = OUT_DIR / "screenshots"


def parse_dt(raw: str) -> datetime | None:
    for fmt in ("%m/%d/%Y %H:%M", "%m/%d/%Y %I:%M %p", "%Y-%m-%d %H:%M:%S"):
        try:
            return datetime.strptime(raw.strip(), fmt)
        except ValueError:
            continue
    return None


def to_int(raw: str) -> int | None:
    raw = (raw or "").strip().replace(",", "")
    try:
        return int(float(raw))
    except (ValueError, TypeError):
        return None


def to_float(raw: str) -> float | None:
    raw = (raw or "").strip().replace(",", "")
    if raw in ("", "-", "--", "NULL", "null", "NA", "N/A"):
        return None
    try:
        return float(raw)
    except ValueError:
        return None


def destination_country(route: str) -> str:
    """Derive destination from route. Mirrors guide DAX:
    RIGHT(Route, LEN(Route) - FIND("-", Route, 1))"""
    route = (route or "").strip()
    idx = route.find("-")
    if idx >= 0:
        return route[idx + 1:].strip()
    return route


def main() -> int:
    if not MASTER.exists():
        print(f"ERROR: master dataset not found: {MASTER}")
        return 1
    with open(MASTER, encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        fields = reader.fieldnames
        rows = list(reader)
    if fields is None:
        print("ERROR: empty header")
        return 1
    print(f"Source: {MASTER.name}  rows={len(rows)}  cols={len(fields)}")

    issues: list[str] = []
    clean_rows = []
    for i, r in enumerate(rows):
        out = dict(r)
        # datetime parsing
        st = parse_dt(r.get("Scheduled_Time", ""))
        et = parse_dt(r.get("Estimated_Time", ""))
        if st is None:
            issues.append(f"row {i}: unparseable Scheduled_Time '{r.get('Scheduled_Time')}'")
        if et is None:
            issues.append(f"row {i}: unparseable Estimated_Time '{r.get('Estimated_Time')}'")
        # Destination Country is derived in the MODEL as a DAX calculated column
        # (guide step: RIGHT(Route, LEN - FIND)), so it is intentionally NOT
        # written to the CSV to avoid a name conflict with the calculated column.
        # numeric coercion (kept as text is fine for import; here we standardise)
        for col in ("Delay_Minutes", "Aircraft_Capacity", "Temperature_C",
                    "Wind_Speed_kmh", "Turnaround_Time", "Taxi_Time",
                    "Queue_Position", "Passenger_Count"):
            v = to_int(r.get(col, ""))
            out[col] = "" if v is None else str(v)
        lf = to_float(r.get("Load_Factor_%", ""))
        out["Load_Factor_%"] = "" if lf is None else str(lf)
        clean_rows.append(out)

    # checks
    dupes = len(clean_rows) - len({r["Flight_ID"] for r in clean_rows})
    if dupes:
        issues.append(f"{dupes} duplicate Flight_ID rows")
    empty_cells = 0
    for r in clean_rows:
        empty_cells += sum(1 for v in r.values() if v in (None, ""))
    print(f"clean rows={len(clean_rows)} empty cells={empty_cells} dupes={dupes}")

    # write clean csv (no derived column — Destination Country is a model calc column)
    out_fields = fields
    OUT_DIR.joinpath("cleaned_data").mkdir(parents=True, exist_ok=True)
    OUTPUTS.mkdir(parents=True, exist_ok=True)
    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    with open(CLEAN, "w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=out_fields)
        writer.writeheader()
        writer.writerows(clean_rows)
    print(f"Wrote {CLEAN} ({CLEAN.stat().st_size} bytes)")

    # ---- profiling for the markdown report ----
    def num_col(col):
        vals = [to_int(r.get(col, "")) for r in clean_rows]
        vals = [v for v in vals if v is not None]
        return vals

    status_c = Counter(r["Status"] for r in clean_rows)
    ftype_c = Counter(r["Flight_Type"] for r in clean_rows)
    airline_c = Counter(r["Airline"] for r in clean_rows)
    route_c = Counter(r["Route"] for r in clean_rows)
    dest_c = Counter(destination_country(r["Route"]) for r in clean_rows)
    weather_c = Counter(r["Weather_Condition"] for r in clean_rows)
    alert_c = Counter(r["Alert_Status"] for r in clean_rows)
    issue_c = Counter(r["Issue_Type"] for r in clean_rows)
    runway_c = Counter(r["Runway"] for r in clean_rows)
    smr_c = Counter(r["SMR_Location"] for r in clean_rows)
    terminal_c = Counter(r["Terminal"] for r in clean_rows)

    delay = num_col("Delay_Minutes")
    pax = num_col("Passenger_Count")
    lf = [to_float(r["Load_Factor_%"]) for r in clean_rows]
    lf = [v for v in lf if v is not None]
    taxi = num_col("Taxi_Time")
    queue = num_col("Queue_Position")

    def stats(vals, fmt=".1f"):
        if not vals:
            return {}
        m = sum(vals) / len(vals)
        sd = math.sqrt(sum((v - m) ** 2 for v in vals) / len(vals))
        return {"n": len(vals), "min": min(vals), "max": max(vals),
                "mean": round(m, 2), "sd": round(sd, 2), "sum": sum(vals)}

    # correlation queue vs taxi
    n = len(queue)
    corr = None
    if n and n == len(taxi):
        mx, my = sum(queue) / n, sum(taxi) / n
        num = sum((queue[i] - mx) * (taxi[i] - my) for i in range(n))
        dx = math.sqrt(sum((x - mx) ** 2 for x in queue))
        dy = math.sqrt(sum((y - my) ** 2 for y in taxi))
        if dx and dy:
            corr = round(num / (dx * dy), 3)

    md = []
    md.append("# BIA/CMB Dataset Profiling — Task D")
    md.append("")
    md.append(f"- Source: `03_Original_Datasets/Task_D/BIA_CMB_Dataset.csv` ({len(clean_rows)} rows × {len(out_fields)} cols)")
    md.append(f"- Clean copy: `cleaned_data/BIA_CMB_clean.csv` ({CLEAN.stat().st_size} bytes)")
    md.append(f"- Unique Flight_IDs: {len(set(r['Flight_ID'] for r in clean_rows))}")
    md.append(f"- Empty cells: {empty_cells} · Duplicate rows: {dupes}")
    md.append(f"- Data issues flagged: {len(issues)}")
    for it in issues[:20]:
        md.append(f"  - ⚠ {it}")
    md.append("")
    md.append("## Categorical distributions")
    md.append("")
    for label, c in [("Status", status_c), ("Flight_Type", ftype_c),
                     ("Weather_Condition", weather_c), ("Alert_Status", alert_c),
                     ("Issue_Type", issue_c), ("Runway", runway_c),
                     ("SMR_Location", smr_c), ("Terminal", terminal_c)]:
        md.append(f"### {label}")
        md.append("")
        for k, v in c.most_common():
            md.append(f"- {k}: {v}")
        md.append("")
    md.append("### Airline")
    md.append("")
    for k, v in airline_c.most_common():
        md.append(f"- {k}: {v}")
    md.append("")
    md.append("### Route (origin→destination)")
    md.append("")
    for k, v in route_c.most_common():
        md.append(f"- {k}: {v}")
    md.append("")
    md.append("### Destination Country (derived)")
    md.append("")
    for k, v in dest_c.most_common():
        md.append(f"- {k}: {v}")
    md.append("")
    md.append("## Numeric statistics")
    md.append("")
    md.append("| Column | n | min | max | mean | sd | sum |")
    md.append("|---|---|---|---|---|---|---|")
    for col in ("Delay_Minutes", "Passenger_Count", "Load_Factor_%",
                "Aircraft_Capacity", "Temperature_C", "Wind_Speed_kmh",
                "Turnaround_Time", "Taxi_Time", "Queue_Position"):
        v = stats(lf if col == "Load_Factor_%" else
                  [to_float(r[col]) for r in clean_rows if to_float(r[col]) is not None])
        if not v:
            md.append(f"| {col} | — | — | — | — | — | — |")
            continue
        md.append(f"| {col} | {v['n']} | {v['min']} | {v['max']} | {v['mean']} | {v['sd']} | {v['sum']} |")
    md.append("")
    if corr is not None:
        md.append(f"- Correlation Queue_Position × Taxi_Time: **{corr}** (bottleneck signal for scatter visual)")
    md.append("")
    md.append("## Avg Delay by dimension (used in DAX spec / report)")
    md.append("")
    md.append("| Airline | avg delay (min) | flights |")
    md.append("|---|---|---|")
    for k, v in airline_c.most_common():
        vals = [to_int(r["Delay_Minutes"]) for r in clean_rows if r["Airline"] == k]
        vals = [x for x in vals if x is not None]
        if vals:
            md.append(f"| {k} | {sum(vals)/len(vals):.1f} | {len(vals)} |")
    md.append("")
    md.append("| Weather | avg delay (min) | flights |")
    md.append("|---|---|---|")
    for k, v in weather_c.most_common():
        vals = [to_int(r["Delay_Minutes"]) for r in clean_rows if r["Weather_Condition"] == k]
        vals = [x for x in vals if x is not None]
        if vals:
            md.append(f"| {k} | {sum(vals)/len(vals):.1f} | {len(vals)} |")
    md.append("")
    md.append("| Destination | flights | passengers |")
    md.append("|---|---|---|")
    for k, v in dest_c.most_common():
        cnt = sum(1 for r in clean_rows if destination_country(r["Route"]) == k)
        p = sum(to_int(r["Passenger_Count"]) or 0 for r in clean_rows if destination_country(r["Route"]) == k)
        md.append(f"| {k} | {cnt} | {p} |")
    md.append("")
    md.append("_Generated by `scripts/task_d_prepare_data.py` — no values invented._")

    (OUTPUTS / "data_profiling.md").write_text("\n".join(md), encoding="utf-8")
    print(f"Wrote {OUTPUTS / 'data_profiling.md'}")

    # machine-readable metrics
    metrics = {
        "rows": len(clean_rows), "cols": len(out_fields),
        "unique_flights": len(set(r["Flight_ID"] for r in clean_rows)),
        "empty_cells": empty_cells, "duplicates": dupes, "issues": issues,
        "corr_queue_taxi": corr,
        "total_passengers": sum(pax), "mean_delay": round(sum(delay)/len(delay), 2),
        "critical_alerts": alert_c.get("Critical", 0),
        "destinations": list(dest_c.keys()),
    }
    (OUTPUTS / "data_metrics.json").write_text(
        json.dumps(metrics, indent=2), encoding="utf-8")
    print(f"Wrote {OUTPUTS / 'data_metrics.json'}")
    print("PREP OK" if not issues else f"PREP DONE with {len(issues)} warnings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
