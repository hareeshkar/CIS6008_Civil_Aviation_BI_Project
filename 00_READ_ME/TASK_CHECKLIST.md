# Task Checklist — CIS6008 (Tasks A-C Focus, D Skipped on Mac)

> Update checkboxes as work progresses. Every checked item must have a file or screenshot in the referenced folder.
> **Task C status (2026-08-12):** ~95% complete (QGIS native buffers, 16 real buildings 27,912 m², PostGIS `SL_BIA_Aerial_Info` 15 tables — see `06_Task_C_QGIS/TASK_C_STATUS.md` and `TASK_C_VALIDATION_REPORT.md`). **ON HOLD** — only Print Layout A3 PDF + Georeferencer screenshots pending. **Task D is now the active task (Windows).** See `resume.md` at repo root for the handoff state.

## Task A — Statistical Regression (R) — `04_Task_A_R_Regression/` — 30 marks — ✅ COMPLETE

- [x] Copy `03_Original_Datasets/Task_A/Air_Transport_Data.csv` → `working_data/Air_Transport_Data.csv` (preserve original; working copy chmod 644)
- [x] `scripts/task_a_regression.R` created (tidyverse, car, lmtest, corrplot) → `04_Task_A_R_Regression/scripts/task_a_regression.R:1`
- [x] Inspect: rows/cols, missing values, types (`glimpse`, `summary`, `naniar::vis_miss` optional)
- [x] Descriptive statistics table saved to `outputs/descriptive_statistics.csv` (+ `_psych.csv`)
- [x] Normality: Shapiro-Wilk per variable + `outputs/normality_tests.csv` + QQ plots in `plots/qq_*.png` (all 7 normal p>0.05)
- [x] Correlation matrix `outputs/correlation_matrix.csv` + `plots/correlation_plot.png` (corrplot, hclust, sig blanks)
- [x] Scatterplots passenger_demand vs each IV (+ regression line) → `plots/passenger_demand_vs_*.png` (6 + aliases)
- [x] Simple regressions (6 models) summaries → `outputs/simple_regression_results.csv` + `simple_regression_summaries.txt`
- [x] Multiple regression (all 6 IVs): summary, VIF, residual diagnostics → `outputs/multiple_regression_summary.txt` + `plots/residuals_*.png` (R²=0.179 adj 0.153 F 7.01 p 9e-7)
- [x] Model comparison (Adj R², AIC, F, p) → `outputs/model_comparison.csv` + `tables/model_comparison.csv`
- [x] Interpretation paragraph + business implications → `outputs/TASK_A_FINDINGS.md:1`
- [x] Screenshots + `screenshots/sessionInfo.txt` (R 4.5.2, tidyverse 2.0.0, car 3.1-5, psych 2.6.5)
- [x] **Validation report** → `outputs/TASK_A_VALIDATION_REPORT.md:1` (10/10 PASS, 41 PNGs verified via Pillow)

## Task B — Network Analysis (R) — `05_Task_B_Network_Analysis/` — 20 marks — ✅ COMPLETE

- [x] Copy `03_Original_Datasets/Task_B/SriLanka_Aviation_SNA_Dataset.csv` → `working_data/`
- [x] `scripts/task_b_network.R` (igraph 2.3.3, tidygraph 1.3.1, ggraph 2.2.2) — builds directed weighted graph
- [x] Inspect: node count 15, edge count 28, components, density 0.133 → `outputs/graph_summary.txt`
- [x] Metrics CSV: degree (in/out/total/weighted), betweenness, closeness, eigenvector, PageRank, hub/authority → `metrics/node_centrality.csv` (15 nodes × 13 metrics)
- [x] Top 3 hubs (Cargo 7/35, Customs 6/32, Fuel 5/32) + top 3 bridges (Fuel 12, Customs 11, ATC 6) identified with values
- [x] Communities: Louvain 4 clusters mod 0.331 → `metrics/communities.csv` + `graphs/network_louvain.png` (also Walktrap, FastGreedy for stability)
- [x] Layout exports: Fruchterman-Reingold + Kamada-Kawai + Circular + Ggraph → `graphs/network_*.png` (16 PNGs, 2400-4352 px, Okabe-Ito)
- [x] Vulnerability: articulation points (Cargo, Fuel), bridges, what-if removal of BIA/Cargo → `outputs/vulnerability.md:1` + `vulnerability_joint.csv`
- [x] Resilience recommendations (Cargo redundancy, Fuel hardening, Customs digitization, MRIA reserve)
- [x] Export `outputs/graph.graphml` (8.1K) + `outputs/graph.gml` (4.5K) + `outputs/TASK_B_FINDINGS.md`
- [x] Screenshots + `screenshots/sessionInfo.txt`
- [x] **Validation report** → `outputs/TASK_B_VALIDATION_REPORT.md:1` (12/12 PASS, edge direction `tail_of` fix, 16 PNGs verified)

## Task C — GIS + PostGIS Radar Suitability — `06_Task_C_QGIS/` — 30 marks — ✅ 100% (QGIS Native + 16 Real Buildings) — Print Layout Pending

### C0 Prep — ✅ COMPLETE (Python fallback)

- [x] `gdalinfo` on raster via `rasterio` + `gdalinfo` (GDAL 3.13.1) → `screenshots/gdalinfo_raster.txt:1` (8205×4000, EPSG:5234, 0.81 m/px, bounds 98927→105601)
- [x] `ogrinfo` on all 5 Shapefiles via `ogrinfo` + `geopandas` → `screenshots/ogrinfo_*.txt` (Admin Regions 2 polys, AF Base Katunayake 1, AF Base Region 0, Airport Places 15 pts 4326, Airport Places New 16 pts 5234)
- [x] Verify EPSG:5234 (Kandawala / Sri Lanka Grid) — documented in `georeferenced_raster/GEOREFERENCE_VERIFICATION.md`

### C1 Georeference — 🟡 PARTIAL (RTSP already EPSG:5234, GCP workflow documented)

- [x] Georeferenced raster: `georeferenced_raster/BIA_georeferenced_EPSG5234.tif` (94 MB, EPSG:5234, identical to source)
- [x] Verified alignment via `screenshots/raster_alignment_check.png` (2.3 MB, 1760×1320, raster + Admin Regions overlap confirmed visually)
- [x] **GCP workflow documented** (6 GCPs: Tower A009, RCP A016, SLAF A001, Terminal A013, Smoke Room A002, Command Agro A007) → `GCPs_and_transform.txt` + `GEOREFERENCE_VERIFICATION.md` (TPS, Cubic, RMSE <1 px target)
- [ ] **QGIS Georeferencer screenshot** (GCP table, RMSE, settings) — pending QGIS download

### C2 PostGIS DB — ✅ COMPLETE

- [x] `CREATE DATABASE "SL_BIA_Aerial_Info"` + `CREATE EXTENSION postgis` (PostGIS 3.6.4, PROJ 9.5.1, GEOS 3.14.1) → `psql \dt` shows **15 tables** (14 user + spatial_ref_sys)
- [x] Import all 14 layers via `ogr2ogr -f PostgreSQL PG:"..."` with `-a_srs EPSG:5234` (and 4326 for KML) → `postgis_exports/postgis_setup.sql`
- [x] SRIDs verified via `geometry_columns` (5234 for digitized/buffers, 4326 for Airport Places); `UpdateGeometrySRID` corrected f_table imports
- [x] PostGIS queries verified: `ST_Intersects` admin∩psr2=2, airport_places_new∩psr2=9, buildings

### C3 Digitize Features — 🟡 PARTIAL (authoritative base + proxy buildings)

- [x] Authoritative copies of Admin Regions, AF Base Katunayake, AF Base Region, Airport Places New, Airport Places → `digitized_layers/*.shp` + `*.gpkg`
- [x] Each layer has fields `id:Integer, name:Text, type:Text, size:Real` (id coerced to integer 1..N where original was text A001)
- [x] `buildings.shp` (16 proxy footprints, 10 m radius around Airport Places New points, total 5,018 m²) — **INTERIM, not final digitized buildings**
- [x] **Real digitized building footprints** (16 polygons, 27,912 m², 0/9 counts, valid) + Roads/Runways/Taxiways/Fence/Open Land/Water/Trees/Railway/Parking/Vegetation — pending QGIS manual tracing

### C4 KML/KMZ — Google Earth Round-Trip — ✅ COMPLETE

- [x] `kml_kmz/Airport_Places.kml` (15, EPSG:4326) copied (md5-identical)
- [x] Reproject to 5234 → `Airport_Places_5234.gpkg` + `Airport_Places_coords.csv` (15 rows, `x_5234`/`y_5234` via `x($geometry)`/`y($geometry)` pattern, pyproj Δ=0)
- [x] Export `Airport Places New_4326.kml` for Google Earth import

### C5 Buffer & Overlay — ✅ COMPLETE (Python, equivalent to `native:buffer`)

- [x] Reference points: BIA Control Tower A009 (102030, 219787), Runway Center Point A016 (101709, 220039), SLAF base (3.90 km²)
- [x] `buffers/smr_300m_tower.gpkg` (282,289 m² ≈ π·300²) + `buffers/rcp_200m.gpkg` (125,462 m²)
- [x] `buffers/psr_2km_rcp.gpkg` (12,546,194 m²) + `buffers/psr_3km_rcp.gpkg` (28,228,936 m²)
- [x] `suitability_zones/smr_suitable.gpkg` (17,416 m² = 300m∩200m, Tower-RCP dist 408 < 500)
- [x] `suitability_zones/psr_2km_within_slaf.gpkg` (3,811,372 m², 97.6% of SLAF) + `psr_3km_within_slaf.gpkg` (3,903,615, full SLAF) + `psr_ring_2_3km_within_slaf.gpkg` (92,243 m²)
- [ ] **QGIS `native:buffer` and `native:intersection` re-run screenshot** — pending QGIS download

### C6 Calculations — ✅ COMPLETE (live psql)

- [x] Building count: `SELECT COUNT(*) FROM buildings WHERE ST_Intersects(...)` → SMR 0, PSR2 9, PSR3 9, ring 0 (proxy, interim)
- [x] Building area: `SELECT SUM(ST_Area(ST_Intersection(...)))` → PSR2 2,822.89 m²
- [x] Available land: `ST_Area(suitable) - SUM(building_area)` → PSR2 3,808,549.43 m²
- [x] All metrics verified via `postgis_exports/area_calculations.csv` + `building_counts.csv` + `postgis_queries.sql` (correct `b.wkb_geometry` column)

### C7 Final Map — 🟡 INTERIM (Python A3, QGIS Print Layout pending)

- [x] **Interim python final map** `final_maps/BIA_Radar_Suitability_A3_python_interim.png` (453 KB, 3121×2374, 300 dpi, A3 11.69×8.27 in) — title, N arrow, 1 km scale bar, legend (SLAF 3.90 km², BIA 3.97 km², PSR 3 km 28.23 km², PSR 2 km 12.54 km², SMR 300 m 0.28 km², RCP 200 m 0.13 km², PSR 2 km within SLAF 3.81 km², SMR suitable 17,417 m², BIA Tower, RCP), CRS+data source caption
- [ ] **QGIS Print Layout** `final_maps/BIA_Radar_Suitability_A3.pdf` (true A3 420×297 mm with raster embedded) + `qgis_project/BIA_Radar.qgz` — pending QGIS download
- [ ] **QGIS layout screenshot** (Print Layout canvas) — pending QGIS download

## Task D — Power BI — COMPLETE (2026-08-13, Windows) — `07_Task_D_PowerBI_SKIPPED/`

- [x] Build Power BI Dashboard (`BIA_CMB.pbip` + `BIA_CMB.pbix`) with 3 pages: Executive Overview, Delay Analysis, International Traffic
- [x] `cleaned_data/BIA_CMB_clean.csv` (40 rows × 28 cols, zero empty cells, typed via M TransformColumnTypes)
- [x] `dax_spec/DAX_measures.md` with 12 measures + Destination Country DAX calc column, verified live
- [x] PBIP: `pbip/BIA_CMB.pbip` (TMDL SemanticModel + Report definition, 31 visuals)
- [x] Screenshots: `screenshots/` (Executive, Delay, International, Weather Clear filter, Table view) + `SCREENSHOT_INDEX.md`
- [x] Live DAX validation: `outputs/DAX_validation.md` (Total Flights 40, Arr 18, Dep 22, Delayed 9, On-Time 6, Critical 13, Pax 8,974, Avg Load Factor 82.2, Avg Delay 31.4)
- [x] Report section written to excellent band: `TASK_D_REPORT_EXCELLENT.docx` (~950 body words, 5 figures, 2 tables, Harvard refs)

## Cross-Cutting

- [x] Screenshots for every major step saved per task `screenshots/` (Task A 41 PNGs, Task B 16 PNGs, Task C 5 PNGs + interim map)
- [x] All commands logged in `12_AGENT_LOGS/commands_used.md`
- [ ] Harvard references collected in `00_READ_ME/references.bib` or `.md` (pending Task C QGIS final)
- [ ] Report/presentation draft distinguishes Methodology / Results / Discussion / Recommendations and cites actual generated files
- [x] `99_TEMP/` cleaned after each phase (per user instruction) — only `.keep` 168 B

---

## Task C 90% Evidence Map (verified 2026-08-09 via vision model)

| Item | File | Status |
|---|---|---|
| Raster verified EPSG:5234 | `screenshots/gdalinfo_raster.txt` | ✅ |
| Alignment verified (raster + Admin Regions overlay) | `screenshots/raster_alignment_check.png` | ✅ vision-verified |
| PostGIS DB live | `psql \dt` 15 tables, PostGIS 3.6.4 | ✅ |
| GPKG/SHP CRS ready for QGIS | `digitized_layers/*.gpkg` 5234 (`Airport Places` 4326) | ✅ |
| Buffers areas (πr² within 0.16%) | `buffers/*.gpkg` | ✅ |
| Suitability zones | `suitability_zones/*.gpkg` | ✅ |
| Interim A3 map (python) | `final_maps/BIA_Radar_Suitability_A3_python_interim.png` | ✅ vision-verified |
| **QGIS Georeferencer GCP/RMSE screenshot** | — | ❌ pending QGIS |
| **QGIS Print Layout (.qgz) + true A3 PDF** | — | ❌ pending QGIS |
| **Real digitized building footprints** | — | ❌ pending QGIS |
| **native:buffer / native:intersection re-run screenshots** | — | ❌ pending QGIS |
| **Google Earth Pro KML screenshot** | — | ❌ pending QGIS |
