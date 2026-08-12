# Clip Info
- Source: BIA_georeferenced_EPSG5234.tif 8205x4000 32.8MP 93.9MB
- CORE 500m pad around Airport Places New (16 pts): [99820.60309587218, 217959.75450192005, 102727.97754414006, 221311.9588484044]
- Clipped window Window(col_off=np.float64(1097.9784939657548), row_off=np.float64(304.5348953108769), width=np.float64(3574.454398450558), height=np.float64(3695.465104689123)) → ~3574x3695 13.2MP (~40% of full) — covers all 16 reference points + AF core
- Created 2026-08-12 via rasterio windowed read, CRS EPSG:5234 preserved, transform updated
- Use for Colab quick test; for radar suitability (PSR 3km) use FULL raster (buffers extend beyond CORE)
