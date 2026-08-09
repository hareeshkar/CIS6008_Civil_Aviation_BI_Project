# Georeferencing Verification — BIA Aerial Latest3_1_modified.tif

## 1. Supplied Raster Verification (Before Digitizing)

**File:** `03_Original_Datasets/Task_C/Raster/Bandaranayake Airport Areal Latest3_1_modified.tif` (94 MB)

**Method:** `rasterio` (via `.venv` `geopandas/rasterio`) — equivalent to `gdalinfo` + `ogrinfo` (Tahoe brew `gdal` currently blocked on `libproj.25`, so python wheel used as validated fallback; QGIS will re-verify after download).

**gdalinfo equivalent (`screenshots/gdalinfo_raster.txt`):**
```
Driver: GTiff
Size: 8205 x 4000
Bands: 3 (uint8)
CRS: EPSG:5234 (Kandawala / Sri Lanka Grid)
Bounds (EPSG:5234): left 98927.53 bottom 218306.16 right 105601.28 top 221559.66
Transform: | 0.81, 0.00, 98927.53|
           | 0.00,-0.81, 221559.66|
Ground Resolution: 0.81 m/px
```

**Interpretation:** Raster already contains EPSG:5234 georeference (GTiff tags `AREA_OR_POINT=Area`, `Transform` + `CRS`). This suggests lecturer pre-georeferenced the “modified” version, but brief still requires student to *demonstrate* georeferencing competency.

## 2. Compliance — Why We Still Document GCP Workflow

Lecturer guide (Task_C_Guide.docx, Section “Before digitizing any features, you must georeference…”):
- Learning outcome is **process**, not just final CRS value.
- Simply stating “already georeferenced, skipped” would **lose marks**.

**Our approach (professional):**
1. **Verify** supplied CRS/bounds/transform and archive screenshot (`screenshots/gdalinfo_raster.txt` + this file).
2. **Recreate/validate** georeferencing in QGIS Georeferencer *as if* starting from raw aerial (see §3), even though source already has tags — satisfies LO and provides appendix screenshots (GCP table, RMSE, transformation).
3. **Keep original** untouched in `03_Original_Datasets/` (chmod 444) and work on copy in `georeferenced_raster/BIA_georeferenced_EPSG5234.tif` (exact copy for now; QGIS will overwrite with Georeferencer output at same path).

## 3. QGIS Georeferencer Workflow (To Be Executed Once QGIS Download Completes)

**QGIS Project CRS:** EPSG:5234 (Kandawala / Sri Lanka Grid) — set in Project → Properties → CRS.

**Source:** Un-referenced copy of aerial (for demonstration, we use `cp` then strip georeference with `gdal_translate -of VRT -gcp ...` or Georeferencer “From scratch”).

**Ground Control Points (GCPs) — selected on stable features visible in both raster and shapefiles:**
| GCP | Raster (pixel,line) → Map (E,N EPSG:5234) | Source | Note |
|-----|-------------------------------------------|--------|------|
| 1 | ~102030,219787 | BIA Control Tower (Airport Places New A009) | Stable vertical feature |
| 2 | 101709,220039 | Runway Center Point A016 | Centreline intersection |
| 3 | 100864,220180 | SLAF Base Katunayake centroid (A001) | Air Force reference |
| 4 | 102077,219174 | Departure Terminal A013 | Terminal corner |
| 5 | 101147,220553 | Smoke Room Practice Area A002 | Northern GCP |
| 6 | 100320,219705 | Command Agro A007 | Western GCP |

*Coordinates taken from `digitized_layers/Airport Places New.shp` (EPSG:5234, already authoritative) and verified against `kml_kmz/Airport_Places_coords.csv` (lat/lon vs x/y).*

**Transformation:** Thin Plate Spline or 1st-order Polynomial — QGIS Georeferencer settings: `Transformation type: Thin Plate Spline`, `Resampling: Cubic`, `Target CRS: EPSG:5234`, `Output: BIA_georeferenced_EPSG5234.tif`, `Compression: LZW`.

**Expected Outputs (to be screenshotted after QGIS):**
- Georeferencer GCP table (6 points, residuals < 1.0 px)
- RMSE report
- `gdalinfo` on output (should match verification above: same bounds/transform/CRS)
- QGIS canvas screenshot with raster + Admin Regions overlay (alignment check)

## 4. Alignment Verification (Pre-QGIS, via geopandas)

- Loaded `Admin Regions.shp` (EPSG:5234) bounds [99713,217622 → 103178,221654] over raster bounds [98927,218306 → 105601,221559] — **overlap confirmed**, no shift.
- Loaded `Airport Places New.shp` points: tower/RCP fall within raster extent and align with runway/taxiway pixels (visual check via matplotlib quick-plot saved as `screenshots/raster_alignment_check.png`).

## 5. Files
- `georeferenced_raster/BIA_georeferenced_EPSG5234.tif` (working copy, 94 MB, EPSG:5234)
- `screenshots/gdalinfo_raster.txt` (rasterio → gdalinfo)
- `screenshots/raster_alignment_check.png` (python matplotlib overlay, to be replaced by QGIS screenshot after download)
- This verification document

*Next: Once QGIS is installed, re-run Georeferencer, capture GCP/RMSE screenshots, and overwrite `BIA_georeferenced_EPSG5234.tif` via QGIS — original remains in 03_.*
