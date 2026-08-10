# buildings_real.gpkg — Real Building Footprints for Task C

**Purpose:** Replace the interim `buildings` proxy (16×10 m circles, 5,018 m²) with real building footprints extracted from the aerial raster.

**Method:** Seed-based raster extraction
- Used 16 known building locations from proxy KML as seeds
- For each seed, extracted bright roof pixels from raster within 80m radius
- Applied adaptive thresholding, morphological cleaning, and polygonization
- Filtered by area (100–15,000 m²), rectangularity, and brightness
- Classified as Terminal/Hangar/Warehouse/Tower/Barracks based on name and area

**Results:**
- 16 buildings extracted (same count as proxy, but real shapes)
- Total area: 27,911.7 m² (vs 5,018.5 m² proxy = +456% increase)
- Range: 148 m² (Smoke Room) to 5,831 m² (Arrival Terminal)

**Schema (required by guide, do not change):**
- `id` : Integer — sequential 1..N
- `name` : Text — building name/ID
- `type` : Text — Terminal, Hangar, Warehouse, Tower, Barracks, Building
- `size` : Real — footprint area in m²
- `geometry` : Polygon — extracted footprint, CRS EPSG:5234

**PostGIS Results:**
- Buildings in SMR suitable: 0
- Buildings in PSR 2km within SLAF: 9
- Building area in PSR 2km: 7,769.3 m²
- Available land SMR: 17,416.6 m²
- Available land PSR 2km: 3,803,603.1 m²

**Files:**
- `buildings_real.gpkg` — GeoPackage with 16 building polygons
- `scripts/extract_buildings_seed.py` — Extraction script
- `outputs/building_mask_raster.tif` — Brightness mask for documentation

**Confidence notes:**
- Most extractions have medium confidence (within 40m of seed)
- Low-confidence fallbacks: ID 1 (Smoke Room), ID 9 (C242 Bilate)
- Manual review recommended for critical analysis
