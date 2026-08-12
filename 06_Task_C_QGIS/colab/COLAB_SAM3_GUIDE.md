# CIS6008 Task C — Colab GPU + SAM3 Guide (Option 2)

**Date:** 2026-08-12 | **Project:** `06_Task_C_QGIS/` | **Raster:** `BIA_georeferenced_EPSG5234.tif` 8205×4000 EPSG:5234 0.81 m/px

This implements **Option 2 — Colab GPU + SAM3 text prompts** you approved. Local M4 test (`99_TEMP/samgeo_test/`) already proved SAM1 (`vit_b` CPU 10.7s/800×800) works but is **not class-specific** and would take ~9 min full + OOM risk. SAM3 gives `building / tree / vegetation / road` directly, but needs GPU.

---

## 1. What the Colab notebook does

* `pip install segment-geospatial[samgeo3]` → `SamGeo3` (backend `meta`, `facebook/sam3.1`)
* Checks `torch.cuda.is_available()` — Colab T4/L4 GPU → `cuda` (local M4 was `cpu` fallback)
* For each prompt `building, tree, vegetation, road`:
  ```python
  sam = SamGeo3(backend="meta", device="cuda")
  sam.generate_masks_tiled(source="BIA_georeferenced_EPSG5234.tif", prompt="building",
                           output="building_mask.tif", tile_size=1024, overlap=128)
  # then vectorize
  from samgeo.common import raster_to_gpkg
  raster_to_gpkg("building_mask.tif", "building.gpkg")
  ```
  Tiled = 1024×1024 + 128 overlap → avoids 32.8 MP OOM on GPU.
* Saves 4 `*_mask.tif` + 4 `*.gpkg` with CRS EPSG:5234 preserved, plus overlay PNGs.

See notebook `SAM3_BIA_Colab.ipynb` — open in Colab and follow.

---

## 2. Files prepared locally

```
06_Task_C_QGIS/georeferenced_raster/BIA_georeferenced_EPSG5234.tif      93.9 MB FULL (8205×4000) — for final radar suitability (PSR 3km)
06_Task_C_QGIS/georeferenced_raster/BIA_CORE_500m_EPSG5234.tif            39.6 MB CORE (3574×3695) 13.2 MP — clipped 500 m pad around 16 Airport Places New pts, covers AF core
06_Task_C_QGIS/georeferenced_raster/CLIP_INFO.md
06_Task_C_QGIS/colab/SAM3_BIA_Colab.ipynb                                 — Colab notebook (4 prompts, tiled)
06_Task_C_QGIS/colab/post_process_colab_outputs.py                        — run after you download GPKGs
99_TEMP/samgeo_test/                                                       — local vit_b proof (62 masks in 10.7s)
```

**Which to upload?**

* **For full WRIT1 compliance (radar PSR 3 km = 28 km²):** upload **FULL** `BIA_georeferenced_EPSG5234.tif` (93 MB). Tiled will take ~15-25 min for 4 prompts on T4.
* **For quick test (<5 min):** upload **CORE** `BIA_CORE_500m_EPSG5234.tif` (39 MB). Covers buildings/vegetation/roads well, but not full PSR 3 km buffer zone. Do not use CORE for final `psr_3km_within_slaf` area if you need full buffer.

---

## 3. Colab steps (5 min setup + 15-25 min run)

1. Go to https://colab.research.google.com → Upload `SAM3_BIA_Colab.ipynb`
2. Runtime → Change runtime type → **T4 GPU** (or L4 if offered) → Save
3. Cell 1: `!nvidia-smi` + `pip install` (first run ~2-3 min, caches `facebook/sam3.1` checkpoint ~? 2 GB)
4. Cell 2: Upload TIFF: Files pane → Upload `BIA_georeferenced_EPSG5234.tif` (or CORE). Or mount Drive.
5. Cell 3: Set `SOURCE = "/content/BIA_georeferenced_EPSG5234.tif"` and run — will loop 4 prompts sequentially, each tiled. **Watch `Total objects found:` per prompt.**
6. Cell 4: Vectorize + preview overlays (matplotlib). Check that `building.gpkg` boundaries look like roofs, not apron slabs.
7. Files pane → Download `*_mask.tif` + `*.gpkg` (or `!zip -r sam3_outputs.zip *.gpkg *.tif *.png`)
8. Back locally: copy to `06_Task_C_QGIS/digitized_layers/colab_raw/` and run `python 06_Task_C_QGIS/colab/post_process_colab_outputs.py`

If Colab says “GPU not available” → Runtime → Restart and try again; free tier sometimes queues.

---

## 4. After Colab — local QA (MANDATORY)

Raw SAM3 output is **candidate polygons**, not authoritative. Run:

```bash
.venv/bin/python 06_Task_C_QGIS/colab/post_process_colab_outputs.py
```

What it does (without overwriting `buildings_manual.gpkg`):

* Reprojects to EPSG:5234 (already), runs `make_valid`, filters by area (building 200-8000 m², tree 10-2000 m², vegetation 50-5000 m², road width proxy via area/aspect), simplifies `0.5*px`, removes holes <50 m², dedupes, adds `id/name/type/size=m²`.
* Saves to `06_Task_C_QGIS/digitized_layers/` as `buildings_sam3.gpkg`, `trees_sam3.gpkg`, `vegetation_sam3.gpkg`, `roads_sam3.gpkg` (each with `id, name, type, size` per Task C guide).
* Keeps raw in `digitized_layers/colab_raw/` for provenance.

Then **manual QA in QGIS** (you must do):

1. Open `QGIS → 06_Task_C_QGIS/qgis_project/BIA_Radar.qgz` → Add `buildings_sam3.gpkg`
2. Delete obvious false positives (apron slabs that look like brown fields in `samgeo_overlay_800_v2.png`, top beige), reshape bad roofs, add any missed obvious buildings.
3. Repeat for vegetation/roads — ensure `roads_auto` is lines, not polygons (may need `native:polygonstolines`).
4. Do **not** claim AI output was hand-digitised. Use statement from `99_TEMP/samgeo_test/SAMGEO_TEST_REPORT.md:9`:
   > Automated segmentation was used to generate candidate vector features from the georeferenced aerial imagery, followed by visual verification and manual correction in QGIS.

---

## 5. Next GIS automation (MCP / qgis_process — ready after QA)

```bash
# Buffers (already have QGIS-native logs in 06_Task_C_QGIS/qgis_process_logs/)
qgis_process run native:buffer -- INPUT=Airport\ Places\ New.shp DISTANCE=300 OUTPUT=buffers/smr_300m_tower.gpkg
qgis_process run native:buffer -- INPUT=RCP.shp DISTANCE=200 OUTPUT=buffers/rcp_200m.gpkg
qgis_process run native:buffer -- INPUT=RCP.shp DISTANCE=2000 OUTPUT=buffers/psr_2km.gpkg
qgis_process run native:buffer -- INPUT=RCP.shp DISTANCE=3000 OUTPUT=buffers/psr_3km.gpkg

# Intersections & area
ogrinfo digitized_layers/buildings_sam3.gpkg -al -so
psql SL_BIA_Aerial_Info -c "SELECT COUNT(*), SUM(ST_Area(geom)) FROM buildings_sam3 WHERE ST_Intersects(geom, (SELECT geom FROM psr_2km))"
```

Update `postgis_exports/area_calculations.csv` and `screenshots/` for appendix.

---

## 6. Troubleshooting

* **Colab OOM on full 8205×4000:** reduce `tile_size` 1024→768 or increase `overlap` 128→192; or use CORE clip first, then full for final buffers.
* **No objects for `road`:** roads are linear, SAM3 may return thin polygons; lower `confidence_threshold` 0.5→0.3 in notebook Cell 3, or switch prompt to `road` + `asphalt road`.
* **`vegetation` vs `tree` overlap:** keep both — `tree` = crowns, `vegetation` = larger green patches. After, `native:difference` to separate.
* **CRS lost:** `raster_to_gpkg` preserves GeoTIFF transform → EPSG:5234. Verify `ogrinfo *.gpkg -al -so | grep EPSG`.

---

## 7. Evidence checklist (for appendix)

* Colab `!nvidia-smi` screenshot → `06_Task_C_QGIS/screenshots/`
* Notebook run log (Found N objects per prompt) → `qgis_process_logs/`
* Raw `building_mask.tif` + `building.gpkg` → `digitized_layers/colab_raw/`
* Cleaned `buildings_sam3.gpkg` attributes (id/name/type/size) → `postgis_exports/`
* Overlay PNGs (local `samgeo_overlay_800_v2.png` + Colab overlays) → `screenshots/`

*Do not delete `99_TEMP/samgeo_test/` until Colab outputs are verified and moved to canonical folders.*

---

**Notebook:** `SAM3_BIA_Colab.ipynb` | **Post-process:** `post_process_colab_outputs.py` | **Local proof:** `99_TEMP/samgeo_test/SAMGEO_TEST_REPORT.md:1`

---

## 8. Fix for `401 Unauthorized / Cannot access gated repo facebook/sam3` (2026-08-12)

You hit:

```
GatedRepoError: 401 Client Error. Cannot access gated repo for url https://huggingface.co/facebook/sam3/resolve/main/config.json.
Access to model facebook/sam3 is restricted. You must have access ...
```

**Cause:** `facebook/sam3` and `facebook/sam3.1` are **gated** (license approval). The notebook tried to download `config.json` anonymously → 401.

**Fix — 2 minutes, in Colab:**

1. **Request access (once per account):**
   - Open https://huggingface.co/facebook/sam3 → click **Agree and access repository** (accept license)
   - Also open https://huggingface.co/facebook/sam3.1 → **Agree** if shown
   - If you see “Access requested” wait ~30s-2 min then refresh until it says “Access granted”.

2. **Create HF token (once):**
   - https://huggingface.co/settings/tokens → **Create new token** → Type **Read** → Copy `hf_xxxxxxxxxxxxxxxxxxxx`

3. **In Colab, run new Cell 1b** (inserted after Cell 1):
   ```python
   HF_TOKEN = "hf_..."  # paste your token
   from huggingface_hub import login
   login(token=HF_TOKEN)
   ```
   The patched notebook (`SAM3_BIA_Colab.ipynb`) now has **Cell 1b — Hugging Face login** that does this + verifies `config.json` download. Paste token, run cell — you should see `Login successful` + `Verified: can access facebook/sam3`.

4. **Re-run Cell 3** (SAM3 tiled). It will now download `sam3.1_multiplex.pt` (~2 GB) with your token and start `building/tree/vegetation/road`.

**Env also set:** `HF_TOKEN` and `HUGGING_FACE_HUB_TOKEN` for subprocesses (Hugging Face Hub v0.26+).

**If still 401 after login:** you forgot to click **Agree** on the model page, or pasted a `Write`/`Fine-grained` token without `Read` scope. Re-check model page shows “You have access”.

**No token? Alternative (not text-prompt):** local SAM1 (`vit_b` CPU, already proven 62 masks/10.7s) + shape filters gives candidates but no semantics. For true `building/tree/road` semantics, SAM3 gated access is currently required. Grounding-DINO+SAM pipeline is an alternative but heavier to set up.

