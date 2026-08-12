#!/usr/bin/env python3
"""
Post-process Colab SAM3 outputs: clean, filter, add id/name/type/size, save to digitized_layers/.

Inputs: 06_Task_C_QGIS/digitized_layers/colab_raw/{building,tree,vegetation,road}.gpkg
        (from Colab /content/sam3_outputs/*.gpkg, CRS EPSG:5234 preserved by raster_to_gpkg)

Outputs: 06_Task_C_QGIS/digitized_layers/{buildings_sam3,trees_sam3,vegetation_sam3,roads_sam3}.gpkg
         + .shp sidecars for QGIS compatibility
         + metrics CSV

Preserves: buildings_manual.gpkg (never overwritten) and 03_Original_Datasets/ (chmod 444).
"""
import pathlib, sys
import geopandas as gpd
import pandas as pd
from shapely.validation import make_valid
from shapely.geometry import Polygon, MultiPolygon
import math

PROJ = pathlib.Path("/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project")
RAW_DIR = PROJ / "06_Task_C_QGIS/digitized_layers/colab_raw"
OUT_DIR = PROJ / "06_Task_C_QGIS/digitized_layers"
METRICS = PROJ / "06_Task_C_QGIS/postgis_exports/sam3_metrics.csv"

# Filter presets per class (tuned after local vit_b test: 62 masks 0.33-19537 m², 40 in 200-8000 m²)
# Pixel 0.81 → 1 px =0.66 m². These are conservative; QA in QGIS will delete remaining false positives.
FILTERS = {
    "building":   {"min_area": 200, "max_area": 8000, "min_rect": 0.40, "min_solid": 0.55, "max_aspect": 7.0, "simplify": 0.4},
    "tree":       {"min_area": 10,  "max_area": 2000, "min_rect": None, "min_solid": None, "max_aspect": None, "simplify": 0.8},
    "vegetation": {"min_area": 50,  "max_area": 5000, "min_rect": None, "min_solid": None, "max_aspect": None, "simplify": 0.8},
    "road":       {"min_area": 100, "max_area": 50000,"min_rect": None, "min_solid": None, "max_aspect": None, "simplify": 0.6},
}

def oriented_metrics(poly):
    rect = poly.minimum_rotated_rectangle
    if rect.is_empty or rect.area <= 0:
        return None
    rect_area = rect.area
    rectangularity = poly.area / rect_area if rect_area>0 else 0
    hull = poly.convex_hull
    solidity = poly.area / hull.area if hull.area>0 else 0
    coords = list(rect.exterior.coords)
    if len(coords) < 5:
        return None
    sides = [math.hypot(coords[i][0]-coords[i+1][0], coords[i][1]-coords[i+1][1]) for i in range(4)]
    longest = max(sides)
    shortest = min(s for s in sides if s>1e-6)
    aspect = longest/shortest if shortest>0 else 99
    return rectangularity, solidity, aspect

def process_one(prompt: str):
    raw = RAW_DIR / f"{prompt}.gpkg"
    if not raw.exists():
        print(f"[SKIP] {prompt}: {raw} not found — did you copy Colab outputs to {RAW_DIR}/?")
        return None
    gdf = gpd.read_file(raw)
    n_raw = len(gdf)
    crs = gdf.crs if gdf.crs else "EPSG:5234"
    # Ensure EPSG:5234
    if gdf.crs is None:
        gdf.set_crs("EPSG:5234", inplace=True)
    elif gdf.crs.to_epsg() != 5234:
        gdf = gdf.to_crs("EPSG:5234")
    # make_valid + remove empties
    gdf["geometry"] = gdf["geometry"].apply(lambda g: make_valid(g) if g and not g.is_valid else g)
    gdf = gdf[~gdf.geometry.is_empty & gdf.geometry.notna()].copy()
    # explode multipolygons to single parts for filtering (keep largest per value if needed)
    gdf = gdf.explode(index_parts=False).reset_index(drop=True)
    filt = FILTERS[prompt]
    kept = []
    for _, row in gdf.iterrows():
        geom = row.geometry
        if not isinstance(geom, (Polygon, MultiPolygon)):
            continue
        # handle MultiPolygon leftover
        parts = [geom] if isinstance(geom, Polygon) else list(geom.geoms)
        for part in parts:
            if part.is_empty or part.area < filt["min_area"] or part.area > filt["max_area"]:
                continue
            # simplify before shape metrics
            simp = part.simplify(filt["simplify"], preserve_topology=True)
            if simp.is_empty or not simp.is_valid:
                simp = make_valid(simp)
                if simp.is_empty:
                    continue
            # For buildings, apply rectangularity/solidity/aspect
            if prompt == "building" and filt["min_rect"] is not None:
                m = oriented_metrics(simp)
                if m is None:
                    continue
                rect, solid, aspect = m
                if rect < filt["min_rect"] or solid < filt["min_solid"] or aspect > filt["max_aspect"]:
                    continue
            # Remove tiny holes (<50 m²)
            if simp.geom_type == "Polygon" and len(simp.interiors) > 0:
                # keep only holes >50 m²
                # reconstruct without small holes
                exterior = simp.exterior
                interiors = [r for r in simp.interiors if Polygon(r).area > 50]
                try:
                    from shapely.geometry import Polygon as Poly
                    simp = Poly(exterior.coords, [list(r.coords) for r in interiors])
                except:
                    pass
            kept.append(simp)
    if not kept:
        print(f"[{prompt}] raw {n_raw} → 0 after filters (check thresholds)")
        return None
    out_gdf = gpd.GeoDataFrame(geometry=kept, crs="EPSG:5234")
    out_gdf["area_m2"] = out_gdf.geometry.area
    out_gdf = out_gdf.sort_values("area_m2", ascending=False).reset_index(drop=True)
    # Add required Task C fields: id, name, type, size
    out_gdf["id"] = range(1, len(out_gdf)+1)
    # name: Building 1 etc., but keep prompt-specific
    prefix = {"building":"Building", "tree":"Tree", "vegetation":"Vegetation", "road":"Road"}[prompt]
    out_gdf["name"] = [f"{prefix} {i}" for i in out_gdf["id"]]
    out_gdf["type"] = prompt.capitalize() if prompt!="vegetation" else "Vegetation"
    # normalize road type to Road
    if prompt=="road":
        out_gdf["type"] = "Road"
    out_gdf["size"] = out_gdf["area_m2"].round(2)
    # reorder columns Task C order
    out_gdf = out_gdf[["id","name","type","size","geometry"]]
    # Save GPKG + SHP sidecar (QGIS needs both)
    name_map = {"building":"buildings_sam3", "tree":"trees_sam3", "vegetation":"vegetation_sam3", "road":"roads_sam3"}
    out_name = name_map[prompt]
    out_gpkg = OUT_DIR / f"{out_name}.gpkg"
    out_shp = OUT_DIR / f"{out_name}.shp"
    if out_gpkg.exists():
        out_gpkg.unlink()
    out_gdf.to_file(out_gpkg, driver="GPKG")
    # also shp (may truncate name length)
    try:
        if out_shp.exists():
            for ext in [".shp",".shx",".dbf",".prj",".cpg"]:
                p = out_shp.with_suffix(ext)
                if p.exists():
                    p.unlink()
        out_gdf.to_file(out_shp, driver="ESRI Shapefile")
    except Exception as e:
        print(f"  shapefile write warning: {e}")
    print(f"[{prompt}] raw {n_raw} → kept {len(out_gdf)} → {out_gpkg.name} ({out_gpkg.stat().st_size/1e6:.2f} MB) total {out_gdf['size'].sum():.1f} m² mean {out_gdf['size'].mean():.1f}")
    return out_gdf

def main():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (PROJ / "06_Task_C_QGIS/postgis_exports").mkdir(parents=True, exist_ok=True)
    print("="*70)
    print("POST-PROCESS COLAB SAM3 OUTPUTS")
    print(f"RAW_DIR {RAW_DIR}")
    print(f"OUT_DIR {OUT_DIR}")
    print("="*70)
    if not any((RAW_DIR / f"{p}.gpkg").exists() for p in ["building","tree","vegetation","road"]):
        print(f"No raw GPKGs in {RAW_DIR}/ — copy Colab outputs first:")
        print("  cp ~/Downloads/*.gpkg 06_Task_C_QGIS/digitized_layers/colab_raw/")
        print("  Expected: building.gpkg, tree.gpkg, vegetation.gpkg, road.gpkg (from raster_to_gpkg)")
        sys.exit(1)
    results = {}
    for prompt in ["building","tree","vegetation","road"]:
        gdf = process_one(prompt)
        if gdf is not None:
            results[prompt] = gdf
    # metrics csv
    rows = []
    for prompt, gdf in results.items():
        rows.append({"prompt":prompt, "output":f"{prompt}_sam3", "count":len(gdf), "total_m2":round(gdf["size"].sum(),1), "mean_m2":round(gdf["size"].mean(),1), "median_m2":round(gdf["size"].median(),1), "min_m2":round(gdf["size"].min(),1), "max_m2":round(gdf["size"].max(),1)})
    if rows:
        df = pd.DataFrame(rows)
        df.to_csv(METRICS, index=False)
        print(f"\nMetrics → {METRICS}")
        print(df.to_string(index=False))
    print("\nNext: QGIS manual QA — open qgis_project/BIA_Radar.qgz, load digitized_layers/*_sam3.gpkg, delete false positives, reshape roofs.")
    print("Do NOT overwrite buildings_manual.gpkg (kept as evidence).")

if __name__ == "__main__":
    main()
