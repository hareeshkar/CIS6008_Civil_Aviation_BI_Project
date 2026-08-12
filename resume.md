# RESUME.md — Handoff State for Windows Agent

> **Read this first.** This repo was developed on **macOS M4** and is being handed to a **Windows laptop** (opencode agent) to continue. It describes exactly what is done, what is on hold, and what to build next.
> **Export date:** 2026-08-12 · **Repo:** `https://github.com/hareeshkar/CIS6008_Civil_Aviation_BI_Project.git` · **Branch:** `main`
>
> **State commit (this resume's content):** `COMMIT_PENDING` — see footer.

---

## 1. TL;DR

- **Task A — Regression: DONE** (30 marks). Reproducible via `Rscript` + project-local `renv`. Validation 10/10.
- **Task B — Network: DONE** (20 marks). Reproducible via `Rscript` + `igraph`. Validation 12/12.
- **Task C — GIS/PostGIS: ESSENTIALLY DONE (~95%), NOW ON HOLD.** Only ~5% polish (QGIS Print Layout A3 PDF + Georeferencer screenshots) remains. **Do NOT resume Task C yet.**
- **Task D — Power BI: BUILD THIS NEXT on Windows.** Prepare cleaned CSV + DAX measures here, then build the `.pbix` dashboard in Power BI Desktop. The `PowerBI_Sample.pbix.zip` in `02_Lecturer_Guides/` is the lecturer's DAX reference.

## 2. Status Snapshot

| Task | Marks | Status | Key Evidence |
|---|---|---|---|
| A — Regression | 30 | ✅ DONE | `04_Task_A_R_Regression/outputs/TASK_A_VALIDATION_REPORT.md` (10/10) + `TASK_A_FINDINGS.md` |
| B — Network | 20 | ✅ DONE | `05_Task_B_Network_Analysis/outputs/TASK_B_VALIDATION_REPORT.md` (12/12) + `TASK_B_FINDINGS.md` |
| C — GIS | 30 | 🟡 ~95% on **HOLD** | `06_Task_C_QGIS/TASK_C_STATUS.md` (100% numeric, QGIS native buffers, 16 real buildings 27,912 m², PostGIS `SL_BIA_Aerial_Info` 15 tables); only final Print Layout PDF pending |
| D — Power BI | 20 | ❌ **NEXT (Windows)** | `07_Task_D_PowerBI_SKIPPED/` — prepare cleaned CSV + DAX spec, then build `.pbix` |

## 3. Where Things Live

```
00_READ_ME/PROJECT_CONTEXT.md     # scope, task map, safety rules — READ FIRST
00_READ_ME/ASSIGNMENT_CRITERIA.md # Excellent (70-100) rubric
00_READ_ME/TASK_CHECKLIST.md      # per-task checkboxes with file evidence
00_READ_ME/SOFTWARE_NOTES.md      # CLI-first tool policy
01_Assignment_Brief/              # PRE1 brief + Task C/D guides + WRIT1 brief
02_Lecturer_Guides/               # guides + PowerBI_Sample.pbix.zip (DAX reference)
03_Original_Datasets/             # MASTER read-only (chmod 444) — never edit
04_Task_A_R_Regression/           # A — R/renv, outputs, plots, validation
05_Task_B_Network_Analysis/       # B — R/igraph, graphs, metrics, validation
06_Task_C_QGIS/                   # C — georeference, PostGIS, buffers, digitization
07_Task_D_PowerBI_SKIPPED/        # D — spec/specials; *.pbix ignored by git
12_AGENT_LOGS/                    # actions/decisions/commands/errors
99_TEMP/                          # transient — cleaned after each phase
```

## 4. Reproduction (any machine)

```bash
# Task A
Rscript 04_Task_A_R_Regression/scripts/task_a_regression.R
# Task B
Rscript 05_Task_B_Network_Analysis/scripts/task_b_network.R
Rscript 05_Task_B_Network_Analysis/scripts/network_graphs_final.R   # Okabe-Ito visuals
```
- R environments are project-local `renv` (`renv/lock.json` inside each task folder) — `renv::restore()` before running.
- Python probe env: `.venv/` (pandas, duckdb, geopandas, rasterio, pyproj, shapely) via `requirements.txt`.
- Seed data is `chmod 444` in `03_Original_Datasets/`; always **copy before transform** into the task's `working_data/`.

## 5. What to Do Next — TASK D (Power BI, Windows)

Follow `01_Assignment_Brief/Task_D_PowerBI_Guide.docx` and mirror the sample DAX in `02_Lecturer_Guides/PowerBI_Sample.pbix.zip`.

1. **Prepare data (script on Mac already planned, or do it here):**
   - Source: `03_Original_Datasets/Task_D/BIA_CMB_Dataset.csv` (7.5K, 28 cols) + `BIA_CMB_Data_Dictionary.pdf`.
   - Clean into `07_Task_D_PowerBI_SKIPPED/cleaned_data/BIA_CMB_clean.csv`: parse `Scheduled_Time`, derive `Destination Country` from `Route`, coerce `Delay_Minutes`, `Passenger_Count`, `Load_Factor_%`.
   - Do **not** commit `.pbix` — gitignored.
2. **DAX measures:** write `dax_spec/DAX_measures.md` from `Task_D_PowerBI_Guide.docx` (Total Flights, Arrivals, Departures, Avg Delay, Delay by Airline, Load Factor, etc.).
3. **Build the dashboard in Power BI Desktop:** 3 pages (Executive, Delay Analysis, International Traffic map) per the guide's 13 screenshots.
4. **Append screenshots** to `07_Task_D_PowerBI_SKIPPED/screenshots/`.

## 6. Task C — Pending Polish (only WHEN you resume C later)

From `06_Task_C_QGIS/TASK_C_STATUS.md`:
- Export true A3 PDF `final_maps/BIA_Radar_Suitability_A3.pdf` from the QGIS Print Layout (`qgis_project/BIA_Radar.qgz`, 13 layers, EPSG:5234).
- Capture QGIS Georeferencer GCP/RMSE screenshot + `native:buffer`/`native:intersection` re-run screenshots.
- Google Earth Pro KML import screenshot (optional).

## 7. Safety Rules for the Windows Agent

- **Never edit** `01_Assignment_Brief/`, `02_Lecturer_Guides/`, `03_Original_Datasets/` (read-only). Copy first.
- Lecturer digitized shapefiles are authoritative — do not redraw/alter geometry independently.
- **Never fabricate** statistics, coordinates, areas, or KPIs. Run the script/query, then write.
- Postgres/PostGIS credentials come from environment variables; never write `.env`/`credentials.json` into the repo.
- Screenshot every major step; append to `12_AGENT_LOGS/actions.md`.

## 8. Handoff Commit Marker

This resume describes the repository state exactly at commit **`COMMIT_PENDING`** (`main`).
The Windows agent should `git pull` and confirm `git rev-parse HEAD` matches the footer, then proceed with Task D.