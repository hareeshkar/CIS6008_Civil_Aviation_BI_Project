# CIS6008 Civil Aviation BI Project — Project Context

> **Agent entry point.** Read this file first before any task. It defines scope, datasets, tools, and safety rules. Refer also to `ASSIGNMENT_CRITERIA.md` for how work is graded (Excellent 70-100 band).

## 1. Goal

Complete **CIS6008 Analytics and Business Intelligence** coursework — using statistical, network, geospatial, and BI tools to generate actionable intelligence for **Sri Lanka's civil aviation sector** (Bandaranaike International Airport — BIA/CMB) to support evidence-based decisions by the **Ministry of Transport, Highways, Ports and Civil Aviation**. On Mac M4, focus on **Tasks A, B, C** (30+20+30 marks); **Task D (Power BI, 20 marks) is SKIPPED on Mac** — only prepare cleaned data + DAX spec for later Windows use.

Module: `CIS6008 Analytics and Business Intelligence`, Semester 2 2026, Leader `induranga@icbtcampus.edu.lk`. Assessment `PRE1` presentation is 20% weighting; practical weighting inferred from brief structure as A 30 / B 20 / C 30 / D 20.

## 1.1 Current Status (2026-08-09)

| Task | Marks | Status | Evidence |
|---|---|---|---|
| **A — Regression** | 30 | ✅ **COMPLETE** | `04_Task_A_R_Regression/outputs/TASK_A_VALIDATION_REPORT.md:1` (10/10 PASS, 34 PNGs vision-verified) + `TASK_A_FINDINGS.md:1` |
| **B — Network** | 20 | ✅ **COMPLETE** | `05_Task_B_Network_Analysis/outputs/TASK_B_VALIDATION_REPORT.md:1` (12/12 PASS, 17 PNGs vision-verified, edge direction fix) + `TASK_B_FINDINGS.md:1` |
| **C — GIS** | 30 | 🟡 **90% (Python+PostGIS)** | `06_Task_C_QGIS/TASK_C_STATUS.md:1` — 100% numeric verified, QGIS-native evidence pending QGIS download |
| **D — Power BI** | 20 | ❌ **SKIPPED (Mac)** | `07_Task_D_PowerBI_SKIPPED/` (empty — task D scoped to Windows) |

Sub-agent max-effort audits: `ses_0194dd4a` (Task B), `ses_0184dc133` (Task C). Vision-verified by main agent via `Read` tool (BIA aerial raster, N arrow, scale bar, all PNGs checked).

---

## 2. Assignment Tasks — Definitive Map

### Task A — Statistical Regression (30 marks) — `04_Task_A_R_Regression/`

- **Dataset (READ-ONLY master):** `03_Original_Datasets/Task_A/Air_Transport_Data.csv` (25K, ~150 rows inferred) + `Air_Transportation_Data_Dictionary.docx`
- **Tool:** `Rscript` CLI — packages `tidyverse, car, lmtest, corrplot, ggplot2, psych` via project-local `renv`
- **Variables:** Dependent = `passenger_demand`; Independents = `airport_traffic, avg_income, fuel_price, avg_ticket_fare, flight_frequency, route_distance`
- **Required analysis:**
  1. Inspect data (missing values, types, distributions)
  2. Descriptive statistics (mean/median/sd by variable)
  3. Normality tests (Shapiro-Wilk per variable + QQ plots)
  4. Correlation matrix + corrplot
  5. Scatterplots (passenger_demand vs each IV)
  6. Simple linear regression (each IV individually)
  7. Multiple linear regression (all IVs) + VIF, residual diagnostics, model comparison (Adj R², AIC, F)
  8. Model interpretation + business implications for demand planning
- **Outputs:** `scripts/task_a_regression.R`, `outputs/*.csv`, `plots/*.png`, `tables/*.tex` or `.csv`, `screenshots/` — never fabricate coefficients.

### Task B — Network Analysis (20 marks) — `05_Task_B_Network_Analysis/`

- **Dataset:** `03_Original_Datasets/Task_B/SriLanka_Aviation_SNA_Dataset.csv` (1.8K) — edge list columns `Source, Target, Relationship {Support,Commercial,Regulatory,Operational}, Weight 1-8`
- **Sample entities:** BIA/CMB, MRIA, CAASL, AASL, SriLankan Airlines, Mihin Lanka, SL Air Force, ATC, Customs & Immigration, Fuel Supply, Cargo, Tourism Authority, International Airlines, Maintenance & Engineering
- **Tool:** `Rscript` + `igraph, tidygraph, ggraph` (renv)
- **Required:**
  1. Construct directed/weighted graph, inspect nodes/edges
  2. Degree centrality (in/out/total), weighted degree
  3. Betweenness centrality (bridge nodes), closeness, eigenvector
  4. Influential hubs, bridge nodes, clusters/communities (Louvain/Walktrap), connectivity & components, density, vulnerability (articulation points, edge criticality)
  5. Resilience recommendations for aviation network
  6. Export graph (GML/GraphML) + metrics CSV, PNG layouts (Fruchterman-Reingold / Kamada-Kawai)
- **Outputs:** `scripts/task_b_network.R`, `metrics/*.csv`, `graphs/*.png`, `outputs/graph.graphml`

### Task C — Geospatial Radar Suitability (30 marks) — `06_Task_C_QGIS/`

- **Sources:** `03_Original_Datasets/Task_C/Raster/Bandaranayake Airport Areal Latest3_1_modified.tif` (94M), `Shapefiles/` (Admin Regions, Air Force Base Katunayake, Air Force Base Region, Airport Places, Airport Places New), `KML_KMZ/Airport Places.kml`, Lecturer guides `01_Assignment_Brief/Task_C_Guide.docx` + `Task_C_DB_Guide.docx`
- **Tools:** `QGIS` (EPSG:5234 SLD99 / Sri Lanka Grid 1999), `qgis_process` CLI, `GDAL/OGR` (`gdalinfo, ogr2ogr, ogrinfo`), `psql` + PostGIS, Google Earth (KML/KMZ import/export)
- **CRS:** **EPSG:5234** mandatory for georeferencing.
- **Workflow (from guides):**
  1. Georeference aerial raster via QGIS Georeferencer (GCPs, EPSG:5234) → `georeferenced_raster/`
  2. Create PostGIS DB `SL_BIA_Aerial_Info` (`CREATE DATABASE`, `CREATE EXTENSION postgis`), import layers via `ogr2ogr` / QGIS DB Manager → `postgis_exports/`
  3. Digitize features: Buildings, Roads, Runways, Taxiways, Airport Fence/Boundary, Open Land, Water Bodies, Trees, Railway, Parking, Vegetation — every vector layer must have fields `id:Integer, name:Text, type:Text, size:Real` (per guide)
  4. Google Earth KML/KMZ: export QGIS layers as KML (EPSG:4326), import back; extract coordinates via Field Calculator `x($geometry)`, `y($geometry)` or Centroids + Add Geometry Attributes
  5. Buffer analysis: `Control Tower` → SMR 300m + RCP 200m rings; `RCP` → PSR/SSR 2km preferred, max 3km; ideally within SLAF base
  6. Overlay: `native:buffer` → `native:intersection` / `native:difference` to find suitable zones → `suitability_zones/`
  7. Calculations: building count (`SELECT COUNT(*)` where `ST_Intersects`), building area (`ST_Area`), available land (`ST_Area(suitable) - SUM(building_area)`)
  8. Final professional map layout (QGIS Print Layout: title, legend, scale bar, north arrow, CRS, data sources) → `final_maps/*.pdf`, `.qgz` project
- **Outputs:** `qgis_project/*.qgz`, `digitized_layers/*.gpkg`, `buffers/*.gpkg`, `suitability_zones/*.gpkg`, `screenshots/` at each major step.

### Task D — Power BI Dashboard (20 marks) — SKIPPED ON MAC

- **Dataset:** `03_Original_Datasets/Task_D/BIA_CMB_Dataset.csv` (7.5K, 28 cols) — cols: `Flight_ID, Airline, Route, Flight_Type, Scheduled_Time, Estimated_Time, Gate, Terminal, Runway, Status, Delay_Minutes, Aircraft_Type, Aircraft_Capacity, Weather_Condition, Temperature_C, Wind_Speed_kmh, PSR_Track_ID, SSR_Code, SMR_Location, Latitude, Longitude, Alert_Status, Issue_Type, Turnaround_Time, Taxi_Time, Queue_Position, Passenger_Count, Load_Factor_%`
- **Decision:** No Power BI Desktop on macOS. Prepare only `07_Task_D_PowerBI_SKIPPED/cleaned_data/BIA_CMB_clean.csv` + `dax_spec/DAX_measures.md` (KPI definitions, e.g., `Total Flights = COUNT(...)` per `Task d Guide.docx`) so Windows build can be reproduced later. No MCP installed for Power BI.

---

## 3. Project Folder Structure (Canonical)

```
CIS6008_Civil_Aviation_BI_Project/
├── 00_READ_ME/                          # ← YOU ARE HERE
│   ├── PROJECT_CONTEXT.md               # this file — scope + task map
│   ├── ASSIGNMENT_CRITERIA.md           # excellent-band grading rubric (separate)
│   ├── TASK_CHECKLIST.md                # per-task checkbox workflow
│   └── SOFTWARE_NOTES.md                # CLI vs MCP token-efficient stack notes
├── 01_Assignment_Brief/                 # copied brief + presentation brief
│   ├── CIS6008_PRE1_Presentation_Brief.pdf
│   ├── Task_C_Guide.docx               # Radar Site Selection workflow
│   ├── Task_C_DB_Guide.docx            # PostGIS/KML workflow (10 embedded PNGs)
│   └── Task_D_PowerBI_Guide.docx       # Dashboard spec (13 PNGs) — reference only
├── 02_Lecturer_Guides/                  # extracted PowerBI sample + guides
│   ├── PowerBI_Sample.pbix.zip + unpacked Report/Layout, DataModel
│   └── Task_C*_Guide.docx              # mirrors 01 for agent convenience
├── 03_Original_Datasets/                # MASTER COPY — NEVER EDIT (chmod 444 on files)
│   ├── README.md
│   ├── Task_A/{Air_Transport_Data.csv, Air_Transportation_Data_Dictionary.docx}
│   ├── Task_B/{SriLanka_Aviation_SNA_Dataset.csv}
│   ├── Task_C/{Raster/*.tif, Shapefiles/*.{shp,shx,dbf,prj}, KML_KMZ/*.kml, Reference_Data/}
│   ├── Task_D/{BIA_CMB_Dataset.csv, BIA_CMB_Data_Dictionary.pdf}
│   └── _RAR_Mirror/ABI-CIS6008-SEP-2026-Dataset - Final/Question-(a..d)/
├── 04_Task_A_R_Regression/{scripts,outputs,plots,tables,screenshots,working_data,renv,.venv}
├── 05_Task_B_Network_Analysis/{scripts,outputs,graphs,metrics,screenshots,working_data,renv}
├── 06_Task_C_QGIS/{qgis_project,georeferenced_raster,digitized_layers,buffers,intersections,suitability_zones,kml_kmz,postgis_exports,final_maps,screenshots,TASK_C_STATUS.md}
├── 07_Task_D_PowerBI_SKIPPED/{cleaned_data,dax_spec,screenshots}  # notes only
├── 12_AGENT_LOGS/{actions.md,decisions.md,errors.md,commands_used.md}
└── 99_TEMP/                             # transient — cleaned after each major phase
```

Original flat files at project root (`ABI-CIS6008...rar` etc.) are kept as provenance but **authoritative copies are inside 01/02/03**.

---

## 4. Rules for Agent (Non-Negotiable)

1. **Never modify** files inside `01_Assignment_Brief/`, `02_Lecturer_Guides/`, `03_Original_Datasets/` (read-only). If `chmod 444` blocks, copy first.
2. **Copy before transform:** `03_.../Task_A/Air_Transport_Data.csv` → `04_.../working_data/Air_Transport_Data_clean.csv`
3. Save all generated work under the relevant task folder only (`04/05/06/07`).
4. Never delete lecturer-provided files.
5. Keep every important command/script (commit to `12_AGENT_LOGS/commands_used.md`).
6. Save screenshots/evidence after major steps (for appendices).
7. Use lecturer guides as primary workflow (`Task C guide` is the recipe).
8. **Do not invent results:** never fabricate regression coefficients, p-values, centrality scores, GIS coordinates, building counts/areas, or Power BI KPIs. Run the analysis first, then write.
9. Do not fabricate citations — use Harvard, only cite actually-read sources.
10. Ask before overwriting final files (`final_maps/*.pdf`, report `.docx`).

---

## 5. Tooling — Token-Efficient Policy (Summary; details in SOFTWARE_NOTES.md)

- **CLI is default** (~200 tokens/call vs MCP 32K-82K / 35× overhead — Firecrawl/mornati 2026 benchmarks). Use MCP only where session-state amortization justifies it.
- **Tasks A+B:** `Rscript` CLI (project-local `renv`), **no R MCP**.
- **Quick CSV inspection:** `duckdb` CLI (global binary; no DuckDB MCP).
- **Task C:** `qgis_process` + `GDAL/OGR` (`gdalinfo, ogr2ogr, ogrinfo`) CLI for geoprocessing (headless, reproducible); `QGIS Agent MCP` (small-context gateway ~20 tokens) only for interactive project/layer/layout manipulation; `nkarasiak/qgis-mcp` (50-100 tools, ~3K token overhead) as backup if needed.
- **Task C DB:** `psql` CLI + PostGIS (`CREATE EXTENSION postgis`); **no Postgres MCP** initially (only if session becomes data-heavy >40% G/N ratio).
- **Task D:** No Power BI MCP on Mac — prepare spec only.
- **File automation:** `python3` in project-local `.venv` + shell; never global `pip install` except documented globals.

---

## 6. Data Provenance

- RAR `ABI-CIS6008-SEP-2026-Dataset - Final.rar` (67M) extracted 2026-08-09 via `unar`/`bsdtar` to `03_.../_RAR_Mirror/`; `99_TEMP/rar_extract` is transient and will be cleaned after verification.
- `PowerBI_Sample.pbix.zip` unpacked in `02_Lecturer_Guides/` (Report/Layout, DataModel etc.) for DAX reference without needing Windows.
- PDF `CIS6008_PRE1_Presentation_Brief.pdf` parsed via `pdftotext`; 10 pages, LO1, Harvard required, 1000-word equivalent, 10-15 slides, title 30-40pt body 20-30pt, no glitz/animations.

---

## 7. Reporting Expectations

- Distinguish **Methodology → Results → Discussion → Recommendations**; use actual generated numbers with units; include residual plots, network layouts, GIS maps.
- Harvard referencing; do not cite AI-generated text as evidence.
- All claims must trace to a file in `outputs/`, `metrics/`, or `postgis_exports/` plus a screenshot.

---

## 8. One-Command Quick Checks (for agent)

```bash
# Inspect CSVs without R
duckdb : "SELECT * FROM read_csv_auto('03_Original_Datasets/Task_A/Air_Transport_Data.csv') LIMIT 5"
# Task A R
Rscript 04_Task_A_R_Regression/scripts/task_a_regression.R
# Task B R
Rscript 05_Task_B_Network_Analysis/scripts/task_b_network.R
# Task C checks
gdalinfo 03_Original_Datasets/Task_C/Raster/Bandaranayake\ Airport\ Areal\ Latest3_1_modified.tif | head -n 60
ogrinfo -al -so 03_Original_Datasets/Task_C/Shapefiles/Admin\ Regions.shp
psql -d SL_BIA_Aerial_Info -c "\dt"
qgis_process list | grep -i buffer
```

---

*Last updated: 2026-08-09. Agent must re-read this file at session start. If `ASSIGNMENT_CRITERIA.md` says “Excellent” requires X, honor it.*
