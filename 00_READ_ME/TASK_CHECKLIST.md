# Task Checklist — CIS6008 (Tasks A-C Focus, D Skipped on Mac)

> Update checkboxes as work progresses. Every checked item must have a file or screenshot in the referenced folder.

## Task A — Statistical Regression (R) — `04_Task_A_R_Regression/` — 30 marks

- [x] Copy `03_Original_Datasets/Task_A/Air_Transport_Data.csv` → `working_data/Air_Transport_Data.csv` (preserve original; working copy chmod 644)
- [x] `scripts/task_a_regression.R` created (tidyverse, car, lmtest, corrplot) → `04_Task_A_R_Regression/scripts/task_a_regression.R:1`
- [x] Inspect: rows/cols, missing values, types (`glimpse`, `summary`, `naniar::vis_miss` optional)
- [x] Descriptive statistics table saved to `outputs/descriptive_stats.csv`
- [x] Normality: Shapiro-Wilk per variable + `outputs/normality_shapiro.csv` + QQ plots in `plots/qq_*.png`
- [x] Correlation matrix `outputs/correlation_matrix.csv` + `plots/corrplot.png`
- [x] Scatterplots passenger_demand vs each IV (+ regression line) → `plots/scatter_*.png`
- [x] Simple regressions (6 models) summaries → `outputs/simple_regression_summary.csv`
- [x] Multiple regression (all 6 IVs): summary, VIF, residual diagnostics → `outputs/multiple_regression_summary.txt` + `plots/residuals_*.png`
- [x] Model comparison (Adj R², AIC, F, p) → `tables/model_comparison.csv`
- [x] Interpretation paragraph + business implications (fuel, frequency, traffic effects)
- [x] Screenshots of RStudio/CLI run + sessionInfo log

## Task B — Network Analysis (R) — `05_Task_B_Network_Analysis/` — 20 marks

- [x] Copy `03_Original_Datasets/Task_B/SriLanka_Aviation_SNA_Dataset.csv` → `working_data/`
- [x] `scripts/task_b_network.R` (igraph, tidygraph, ggraph) — builds directed weighted graph
- [x] Inspect: node count, edge count, components, density → `outputs/graph_summary.txt`
- [x] Metrics CSV: degree (in/out/total/weighted), betweenness, closeness, eigenvector → `metrics/node_centrality.csv`
- [x] Top 3 hubs (degree) + top 3 bridges (betweenness) identified with values
- [x] Communities: Louvain/Walktrap → `metrics/communities.csv` + `graphs/network_louvain.png`
- [x] Layout exports: Fruchterman-Reingold + Kamada-Kawai → `graphs/network_*.png`
- [x] Vulnerability: articulation points, edge criticality, what-if removal of BIA/CAASL → `outputs/vulnerability.md`
- [x] Resilience recommendations (redundancy, MRIA, coordination)
- [x] Export `outputs/graph.graphml` + `outputs/graph.gml`
- [x] Screenshots

## Task C — GIS + PostGIS Radar Suitability — `06_Task_C_QGIS/` — 30 marks — Lecturer guide is the recipe

### C0 Prep

- [ ] `gdalinfo` on `03_Original_Datasets/Task_C/Raster/Bandaranayake Airport Areal Latest3_1_modified.tif` logged to `screenshots/gdalinfo.txt`
- [ ] `ogrinfo` on each Shapefile logged
- [ ] Verify EPSG:5234 in QGIS; document CRS string

### C1 Georeference (Mandatory)

- [ ] Georeference raster via QGIS Georeferencer (GCPs, EPSG:5234, transformation + resampling noted) → `georeferenced_raster/BIA_georeferenced.tif`
- [ ] Screenshot GCP table + RMSE + Georeferencer settings

### C2 PostGIS DB

- [ ] `CREATE DATABASE "SL_BIA_Aerial_Info"` + `CREATE EXTENSION postgis` via `psql` (log commands in `12_AGENT_LOGS/commands_used.md`)
- [ ] Import layers via `ogr2ogr -f PostgreSQL` or DB Manager → `postgis_exports/` (shapefile → DB)
- [ ] Verify: `psql -d SL_BIA_Aerial_Info -c "\dt"` screenshot + `SELECT PostGIS_version()`

### C3 Digitize Features

- [ ] Digitize Buildings, Roads, Runways, Taxiways, Airport Fence, Open Land, Water Bodies, Trees, Railway, Parking, Vegetation (as visible) → `digitized_layers/*.gpkg`
- [ ] Each layer has fields `id:Integer, name:Text, type:Text, size:Real` — attribute table screenshots

### C4 KML/KMZ — Google Earth Round-Trip

- [ ] Export Buildings/Roads as KML (EPSG:4326) → `kml_kmz/`
- [ ] Import KML back to QGIS; Centroids → Add Geometry Attributes → extract `x($geometry)`, `y($geometry)` (Field Calculator screenshots)
- [ ] Export CSV with lat/lon + intersection of centroids with building polygons

### C5 Buffer & Overlay — Radar Suitability

- [ ] Identify/reference point: Control Tower + RCP (Runway Crossing Point) + SLAF base polygon
- [ ] `qgis_process run native:buffer` → SMR 300m from tower (`buffers/smr_300m.gpkg`), SMR 200m from RCP (`buffers/rcp_200m.gpkg`)
- [ ] PSR/SSR 2km preferred + 3km max from RCP (`buffers/psr_2km.gpkg`, `buffers/psr_3km.gpkg`)
- [ ] `native:intersection` + `native:difference` → suitable zones → `suitability_zones/smr_suitable.gpkg`, `psr_suitable.gpkg`
- [ ] Preferably within SLAF base: `intersection` with `Air Force Base Katunayake` → check

### C6 Calculations

- [ ] Building count in suitable zones: `SELECT COUNT(*) FROM buildings WHERE ST_Intersects(buildings.geom, suitable.geom)` → log result
- [ ] Building area: `SELECT SUM(ST_Area(geom))` per zone
- [ ] Available land: `ST_Area(suitable) - SUM(building_area)` → `outputs/building_counts.csv`, `outputs/area_calcs.csv`

### C7 Final Map

- [ ] QGIS Print Layout: title, legend, scale bar, north arrow, CRS EPSG:5234 note, data sources, date, author → `final_maps/BIA_Radar_Suitability_A3.pdf`
- [ ] Export `qgis_project/BIA_Radar.qgz` + layout screenshot

## Task D — Power BI — SKIPPED ON MAC — `07_Task_D_PowerBI_SKIPPED/`

- [ ] Copy `03_Original_Datasets/Task_D/BIA_CMB_Dataset.csv` → `cleaned_data/BIA_CMB_clean.csv` (clean: parse Scheduled_Time, derive Destination Country from Route)
- [ ] `dax_spec/DAX_measures.md` with KPI definitions from `Task d Guide.docx` (Total Flights, Arrivals, Departures, Avg Delay, Delay by Airline, Load Factor etc.) — sample DAX provided but not executed on Mac
- [ ] Wireframe/layout note for 3 pages (Executive, Delay Analysis, International Traffic map) — reference only; no `.pbix` claimed
- [ ] Note in report: “Built spec on Mac; dashboard to be built on Windows/Power BI Desktop”

## Cross-Cutting

- [ ] Screenshots for every major step saved per task `screenshots/`
- [ ] All commands logged in `12_AGENT_LOGS/commands_used.md`
- [ ] Harvard references collected in `00_READ_ME/references.bib` or `.md`
- [ ] Report/presentation draft distinguishes Methodology / Results / Discussion / Recommendations and cites actual generated files
- [ ] `99_TEMP/` cleaned after each phase (per user instruction)
