# CIS6008 Civil Aviation BI Project

**Statistical, Network & Geospatial Analysis for Sri Lanka's Civil Aviation (BIA/CMB)**

CIS6008 Analytics and Business Intelligence — Semester 2 2026  
Student: Hareesh Kar · ICBT Campus · Cardiff Metropolitan University

This repo contains practical work for Tasks **A–C** (Power BI deferred to Windows). Each task is reproducible via `Rscript` and documents every numeric claim with traceable outputs.

---

## Project Structure

```
00_READ_ME/                  # context, assignment criteria, checklists, software notes
01_Assignment_Brief/         # PRE1 brief + Task C/D guides
02_Lecturer_Guides/          # guides + PowerBI sample (unpacked)
03_Original_Datasets/        # master copies (read-only) — Task A/B/C/D + raster
04_Task_A_R_Regression/      # R: descriptive, normality, correlation, simple/multiple regression
05_Task_B_Network_Analysis/  # R/igraph: centralities, communities, vulnerability
06_Task_C_QGIS/              # QGIS + PostGIS — radar suitability (georeference, buffers, PostGIS)
07_Task_D_PowerBI_SKIPPED/   # spec only on Mac — cleaned CSV + DAX plan
12_AGENT_LOGS/               # actions, decisions, commands
```

---

## Tasks

| Task | Marks | Tool | Key Outputs |
|---|---|---|---|
| **A — Regression** (30) | `Rscript` `renv` | `passenger_demand ~ 6 IVs`, normality, corrplot, scatter + lm, VIF, diagnostics |
| **B — Network** (20) | `Rscript` `igraph` | 15 nodes / 28 edges, degree/betweenness, Louvain 4 clusters, articulation, resilience |
| **C — GIS** (30) | `QGIS` `qgis_process` `GDAL` `psql` | EPSG:5234 georeference, SMR 300/200m, PSR/SSR 2/3 km, PostGIS `SL_BIA_Aerial_Info` |
| **D — Power BI** (20) | *Skipped on Mac* | Cleaned `BIA_CMB` CSV + DAX measures for Windows build |

---

## Quick Start (Mac M4)

```bash
# Task A — 200 rows, 0 missing
Rscript 04_Task_A_R_Regression/scripts/task_a_regression.R
open 04_Task_A_R_Regression/plots/correlation_plot.png
cat 04_Task_A_R_Regression/outputs/TASK_A_FINDINGS.md

# Task B — 15 nodes, 28 edges
Rscript 05_Task_B_Network_Analysis/scripts/task_b_network.R
Rscript 05_Task_B_Network_Analysis/scripts/network_graphs_final.R  # enhanced visuals (Okabe-Ito)
open 05_Task_B_Network_Analysis/graphs/network_fruchterman.png

# Env
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
Rscript -e "renv::restore()"  # inside 04_Task_A_R_Regression or 05_Task_B...
```

---

## Methodology & Results

- **Task A:** Only `airport_traffic` strongly predicts demand (r=0.385, R² 0.149, p<1e-7); multiple R² 0.179 adj 0.153, F 7.01 p<1e-6 — low explanatory power honestly reported. All diagnostics pass (VIF ~1.05, BP p0.56, DW 2.07).
- **Task B:** Cargo Operators (deg 7) and Fuel Supply (between 12) are critical; Louvain finds 4 clusters (mod 0.33); articulation points Cargo/Fuel fragment network.
- **Task C:** In progress — follows `Task_C_Guide.docx` stepwise (georeference → PostGIS → digitize → buffers → land calc).

Every claim cites `outputs/`, `metrics/`, or `psql` output — no invented numbers.

---

## Submission

Report and `PRE1` slides are built from `04/05/06` outputs with Harvard referencing. Appendices include `screenshots/` and `12_AGENT_LOGS/`.

---

*This repo is coursework, not production — data are provided for academic use.*
