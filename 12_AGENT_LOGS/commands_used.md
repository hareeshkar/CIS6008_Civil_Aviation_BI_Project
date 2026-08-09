# Commands Used — Chronological Log

## 2026-08-09 — Skeleton + Extraction
```bash
mkdir -p 00_READ_ME 01_Assignment_Brief 02_Lecturer_Guides 03_Original_Datasets/Task_A ...
cp "Task C guide.docx" "01_Assignment_Brief/Task_C_Guide.docx"
cp "icbtcis6008s3sripres1may-2026main2025-26 (2).pdf" "01_Assignment_Brief/CIS6008_PRE1_Presentation_Brief.pdf"
unzip -o "02_Lecturer_Guides/PowerBI_Sample.pbix.zip" -d "02_Lecturer_Guides/"
brew install unar
bsdtar -xf "ABI-CIS6008-SEP-2026-Dataset - Final.rar" -C "99_TEMP/rar_extract"
cp "Question-(a)/Air_Transport_Data.csv" "03_Original_Datasets/Task_A/"
cp "Question-(c)/Bandaranayake Airport Areal Latest3_1_modified.tif" "03_Original_Datasets/Task_C/Raster/"
cp "Question-(c)/Admin Regions."* "03_Original_Datasets/Task_C/Shapefiles/"
cp -R "ABI-CIS6008-SEP-2026-Dataset - Final" "03_Original_Datasets/_RAR_Mirror/"
chmod 444 03_Original_Datasets/Task_A/* 03_Original_Datasets/Task_B/* 03_Original_Datasets/Task_C/Raster/* 03_Original_Datasets/Task_C/Shapefiles/* 03_Original_Datasets/Task_C/KML_KMZ/* 03_Original_Datasets/Task_D/*
```
```

## 2026-08-09 — Toolchain Verification (after venv + R renv + duckdb installs)
```bash
Rscript --version            # Rscript (R) version 4.5.2 (2025-10-31)
.venv/bin/python --version   # Python 3.11.14
.venv/bin/pip list           # pandas 3.0.5, duckdb 1.5.5, psycopg2-binary 2.9.12, openpyxl 3.1.5, pypdf 6.15.0
duckdb --version             # v1.5.5 (Variegata) d8cdaa33fd
psql --version               # psql (PostgreSQL) 18.3 (Homebrew) — server currently fails to start due to missing /opt/homebrew/opt/icu4c@78/lib/libicui18n.78.dylib (Tahoe pre-release issue, needs `brew reinstall icu4c@78 postgresql@18` before Task C DB phase)
gdalinfo --version           # BROKEN — dyld libarrow_dataset.2400.dylib missing (needs `brew reinstall apache-arrow gdal` — also Tahoe issue, defer to Task C processing phase)
ogrinfo --version            # BROKEN same as gdalinfo
qgis_process                 # NOT FOUND — needs `brew install --cask qgis` (~1.1G, defer to Task C if QGIS required; alternative is Python geopandas for headless buffers)
R packages: tidyverse:2.0.0, car:3.1.5, lmtest:0.9.40, corrplot:0.95, psych:2.6.5, igraph:2.3.3, tidygraph:1.3.1, ggraph:2.2.2, renv:1.2.4
CSV row counts (venv duckdb): Task_A Air_Transport_Data.csv 200 rows, Task_B SNA 28 edges, Task_D BIA_CMB 40 rows
```

## 2026-08-09 — Task C 90% Vision Verification Commands
```bash
# Vision verification (Read tool on images)
# Sub-agent and main agent both confirmed:
# - raster_alignment_check.png: raster visible, Admin Regions overlay, Tower/RCP labelled
# - BIA_Radar_Suitability_A3_python_interim.png: A3 11.69x8.27in 300dpi, N arrow, scale bar, legend, CRS
# - correlation_plot.png: airport_traffic r=0.39, n=200
# - network_fruchterman.png: 15 nodes, weighted arrows, Okabe palette, 4 Louvain clusters

# Task C status: 90% via Python+PostGIS fallback
# PostGIS DB live: SL_BIA_Aerial_Info 15 tables, PostGIS 3.6.4
# All buffers/suitability zones verified via shapely + psql ST_Area (Δ=0)
# Buildings = 16x10m proxy (interim, 0/9/9/0 counts, 5018 m²)
# Georeference: 6 GCPs documented, TPS+Cubic, RMSE <1px pending QGIS screenshot
```
