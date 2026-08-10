# buildings_real.gpkg — Manual Digitization Layer for Task C

**Purpose:** Replace the interim `buildings` proxy (16×10 m circles, 5,018 m²) with real building footprints traced from the aerial raster.

**Schema (required by guide, do not change):**
- `id` : Integer — sequential 1..N
- `name` : Text — building name/ID (e.g., "Terminal 1", "Hangar A", or auto "Building 1")
- `type` : Text — e.g., "Terminal", "Hangar", "Warehouse", "Control Tower Annex" (not the tower itself — tower is separate point)
- `size` : Real — footprint area in m², calculated via Field Calculator: `size = $area` (after digitizing, run Field Calculator to populate)
- `geometry` : Polygon — traced footprint, CRS EPSG:5234

**How to digitize in QGIS (while QGIS is open):**
1. In QGIS, Layer → Add Layer → Add Vector Layer → select `digitized_layers/buildings_real.gpkg` (EPSG:5234)
2. Right-click layer → Toggle Editing → Add Polygon Feature
3. Zoom to aerial raster `georeferenced_raster/BIA_georeferenced_EPSG5234.tif` — trace ~10-15 visible building polygons (terminal buildings, hangars, warehouses near runway/apron). Avoid tracing shadows, aircraft, roads, vegetation — only roof footprints.
4. For each polygon, fill Attributes: id (1,2,3...), name (e.g., "Building 1"), type (e.g., "Terminal"), size will be auto-calculated next step
5. After tracing all, open Attribute Table → Toggle Editing → Field Calculator → Update existing field `size` → Expression: `$area` → OK → Save
6. Project → Save As `qgis_project/BIA_Radar.qgz` (overwrite placeholder 692B file)
7. Then replace proxy in PostGIS: In QGIS DB Manager or via `ogr2ogr -f PostgreSQL PG:"dbname=SL_BIA_Aerial_Info" digitized_layers/buildings_real.gpkg -nln buildings -overwrite -a_srs EPSG:5234` or via `qgis_process`
8. Rerun PostGIS queries:
   ```
   SELECT COUNT(*) FROM buildings WHERE ST_Intersects(wkb_geometry, (SELECT geom FROM smr_suitable));
   SELECT SUM(ST_Area(wkb_geometry)) FROM buildings WHERE ST_Intersects(wkb_geometry, (SELECT geom FROM smr_suitable));
   SELECT COUNT(*) FROM buildings WHERE ST_Intersects(wkb_geometry, (SELECT geom FROM psr_2km_within_slaf));
   ```
   Update `postgis_exports/area_calculations.csv` and `building_counts.csv` with real values.

**For now:** This file is empty (0 rows) and ready. The proxy `buildings.shp` (16×10 m) remains in PostGIS as `buildings` until you replace it — do not use proxy numbers in final report.

**QGIS project ready:** `qgis_project/BIA_Radar.qgz` already contains CRS EPSG:5234, but will be overwritten with full layers after you digitize.
