#!/usr/bin/env python3
"""
Building Footprint Extraction — Seed-Based Approach
===================================================
Uses known building locations (from proxy KML) as seeds, then extracts
actual building footprints from the raster around each seed.

This avoids false positives from bright surfaces that aren't buildings.
"""

import os, sys, warnings
import numpy as np
import rasterio
from rasterio.features import shapes, rasterize
from shapely.geometry import shape, Polygon, MultiPolygon, mapping, box
from shapely.ops import unary_union
from shapely.validation import make_valid
import geopandas as gpd
from scipy import ndimage
from skimage import morphology, filters, measure
warnings.filterwarnings('ignore')

PROJECT = '/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project'
RASTER = os.path.join(PROJECT, '06_Task_C_QGIS/georeferenced_raster/BIA_georeferenced_EPSG5234.tif')
PROXY_SHP = os.path.join(PROJECT, '06_Task_C_QGIS/digitized_layers/buildings.shp')
OUTPUT_GPKG = os.path.join(PROJECT, '06_Task_C_QGIS/digitized_layers/buildings_real.gpkg')
OUTPUT_DIR = os.path.join(PROJECT, '06_Task_C_QGIS/outputs')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Search radius around each seed (meters)
SEARCH_RADIUS = 80  # look within 80m of seed for the actual building
MIN_BLDG_AREA = 100  # minimum building area (m²)
MAX_BLDG_AREA = 15000  # maximum (avoid huge slabs)


def classify_building(name, area, cx, cy, bounds):
    """Classify building type based on name and area."""
    name_lower = name.lower()
    if 'terminal' in name_lower:
        return 'Terminal'
    elif 'hangar' in name_lower:
        return 'Hangar'
    elif 'cargo' in name_lower or 'warehouse' in name_lower:
        return 'Warehouse'
    elif 'control tower' in name_lower:
        return 'Control Tower'
    elif 'car park' in name_lower or 'parking' in name_lower:
        return 'Car Park'
    elif 'mess' in name_lower or 'billet' in name_lower:
        return 'Barracks'
    elif 'tower' in name_lower:
        return 'Tower'
    elif area > 3000:
        return 'Large Building'
    elif area > 1000:
        return 'Medium Building'
    else:
        return 'Building'

print("=" * 70)
print("SEED-BASED BUILDING FOOTPRINT EXTRACTION — BIA")
print("=" * 70)

# ---- Load known building locations ----
print("\n[1/6] Loading known building locations...")
proxy = gpd.read_file(PROXY_SHP)
print(f"  Loaded {len(proxy)} seed buildings")

# ---- Read raster ----
print("\n[2/6] Reading raster...")
with rasterio.open(RASTER) as src:
    r_full = src.read(1).astype(np.float32)
    g_full = src.read(2).astype(np.float32)
    b_full = src.read(3).astype(np.float32)
    transform = src.transform
    inv_transform = ~transform
    crs = src.crs
    bounds = src.bounds
    height, width = r_full.shape
    res_x, res_y = src.res

gray_full = 0.2989 * r_full + 0.5870 * g_full + 0.1140 * b_full

print(f"  Raster: {width}x{height}, resolution={res_x:.3f}m/px")

# ---- Process each seed building ----
print("\n[3/6] Extracting footprints for each seed building...")
buildings = []

for idx, row in proxy.iterrows():
    seed_id = int(row['id'])
    seed_name = str(row.get('Name', row.get('name', f'Building {seed_id}')))
    seed_geom = row.geometry
    seed_cx = seed_geom.centroid.x
    seed_cy = seed_geom.centroid.y
    
    # Define search box around seed
    search_box = box(seed_cx - SEARCH_RADIUS, seed_cy - SEARCH_RADIUS,
                     seed_cx + SEARCH_RADIUS, seed_cy + SEARCH_RADIUS)
    
    # Clip search box to raster bounds
    search_box = search_box.intersection(box(bounds.left, bounds.bottom, bounds.right, bounds.top))
    if search_box.is_empty:
        print(f"  [{seed_id:>2d}] {seed_name}: seed outside raster, skipping")
        continue
    
    minx, miny, maxx, maxy = search_box.bounds
    
    # Convert to pixel coordinates
    col_off, row_off = inv_transform * (minx, maxy)
    col_end, row_end = inv_transform * (maxx, miny)
    
    r0 = max(0, int(row_off))
    r1 = min(height, int(row_end) + 1)
    c0 = max(0, int(col_off))
    c1 = min(width, int(col_end) + 1)
    
    if r1 <= r0 or c1 <= c0:
        print(f"  [{seed_id:>2d}] {seed_name}: empty search window, skipping")
        continue
    
    # Extract local raster patch
    local_r = r_full[r0:r1, c0:c1]
    local_g = g_full[r0:r1, c0:c1]
    local_b = b_full[r0:r1, c0:c1]
    local_gray = gray_full[r0:r1, c0:c1]
    
    # Local transform for this patch
    local_transform = rasterio.transform.from_bounds(
        bounds.left + c0 * res_x, bounds.top - r1 * res_y,
        bounds.left + c1 * res_x, bounds.top - r0 * res_y,
        c1 - c0, r1 - r0
    )
    
    # Find bright pixels (potential roof) — adaptive threshold
    # Use local mean as threshold (buildings are brighter than surroundings)
    local_mean = local_gray.mean()
    local_std = local_gray.std()
    bright_thresh = max(local_mean + 0.5 * local_std, 100)
    
    bright_mask = local_gray > bright_thresh
    
    # Remove very dark areas (shadows, vegetation)
    shadow = local_gray < 40
    ndvi = (local_g.astype(float) - local_r.astype(float)) / (local_g.astype(float) + local_r.astype(float) + 1e-6)
    veg = (ndvi > 0.2) | ((local_g > local_r * 1.3) & (local_g > local_b * 1.2) & (local_gray < 80))
    
    bright_mask = bright_mask & ~shadow & ~veg
    
    # Morphological cleaning
    selem = morphology.disk(2)
    cleaned = morphology.remove_small_objects(bright_mask, min_size=30)
    cleaned = morphology.opening(cleaned, selem)
    cleaned = morphology.closing(cleaned, selem)
    
    # Label connected components
    labeled, num_feat = ndimage.label(cleaned)
    
    if num_feat == 0:
        # Fallback: use the seed point's area estimate
        seed_area = seed_geom.area
        print(f"  [{seed_id:>2d}] {seed_name}: no bright region found, using seed area {seed_area:.0f} m²")
        buildings.append({
            'id': seed_id,
            'name': seed_name,
            'type': classify_building(seed_name, seed_area, seed_cx, seed_cy, bounds),
            'size': round(seed_area, 2),
            'geometry': seed_geom,
            'confidence': 'low',
            'method': 'seed_fallback'
        })
        continue
    
    # Find the component closest to seed center
    seed_local_x = int((seed_cx - (bounds.left + c0 * res_x)) / res_x)
    seed_local_y = int(((bounds.top - r0 * res_y) - seed_cy) / res_y)
    
    best_poly = None
    best_dist = float('inf')
    best_area = 0
    
    for feat_id in range(1, num_feat + 1):
        feat_mask = (labeled == feat_id)
        feat_area_pixels = feat_mask.sum()
        feat_area_m2 = feat_area_pixels * res_x * res_y
        
        if feat_area_m2 < MIN_BLDG_AREA or feat_area_m2 > MAX_BLDG_AREA:
            continue
        
        # Find centroid of this feature
        feat_ys, feat_xs = np.where(feat_mask)
        feat_cx_local = feat_xs.mean()
        feat_cy_local = feat_ys.mean()
        
        # Distance to seed
        dist = np.sqrt((feat_cx_local - seed_local_x)**2 + (feat_cy_local - seed_local_y)**2) * res_x
        
        if dist < best_dist and dist < SEARCH_RADIUS:
            best_dist = dist
            best_area = feat_area_m2
            
            # Create polygon from this feature's mask
            feat_uint8 = feat_mask.astype(np.uint8)
            for geom, val in shapes(feat_uint8, mask=feat_uint8, transform=local_transform):
                if val == 1:
                    p = shape(geom)
                    if p.is_valid and not p.is_empty:
                        if best_poly is None or p.area > best_poly.area:
                            best_poly = p
    
    if best_poly is not None and best_poly.area > MIN_BLDG_AREA:
        # Simplify polygon to remove pixelation
        simplified = best_poly.simplify(1.0, preserve_topology=True)
        if not simplified.is_valid:
            simplified = make_valid(simplified)
        
        actual_area = simplified.area
        print(f"  [{seed_id:>2d}] {seed_name}: extracted {actual_area:.0f} m² (dist={best_dist:.1f}m)")
        buildings.append({
            'id': seed_id,
            'name': seed_name,
            'type': classify_building(seed_name, actual_area, seed_cx, seed_cy, bounds),
            'size': round(actual_area, 2),
            'geometry': simplified,
            'confidence': 'high' if best_dist < 20 else 'medium',
            'method': 'raster_extract'
        })
    else:
        # Fallback to seed polygon
        seed_area = seed_geom.area
        print(f"  [{seed_id:>2d}] {seed_name}: no suitable region, using seed ({seed_area:.0f} m²)")
        buildings.append({
            'id': seed_id,
            'name': seed_name,
            'type': classify_building(seed_name, seed_area, seed_cx, seed_cy, bounds),
            'size': round(seed_area, 2),
            'geometry': seed_geom,
            'confidence': 'low',
            'method': 'seed_fallback'
        })

print(f"\n  Total buildings extracted: {len(buildings)}")

# ---- Create GeoDataFrame ----
print("\n[4/6] Creating GeoDataFrame...")
records = []
for b in buildings:
    records.append({
        'id': b['id'],
        'name': b['name'],
        'type': b['type'],
        'size': b['size'],
        'geometry': b['geometry']
    })

gdf = gpd.GeoDataFrame(records, crs='EPSG:5234')
gdf['geometry'] = gdf['geometry'].apply(lambda g: make_valid(g) if not g.is_valid else g)

# ---- Save ----
print("\n[5/6] Saving to GeoPackage...")
if os.path.exists(OUTPUT_GPKG):
    os.remove(OUTPUT_GPKG)
gdf.to_file(OUTPUT_GPKG, driver='GPKG', layer='buildings_real')

print(f"  Saved {len(gdf)} buildings to {OUTPUT_GPKG}")

# ---- Summary ----
print("\n[6/6] Summary:")
print(f"  Total buildings: {len(gdf)}")
print(f"  Total area: {gdf['size'].sum():.1f} m²")
print(f"  By type:")
for t, cnt in gdf['type'].value_counts().items():
    a = gdf[gdf['type'] == t]['size'].sum()
    print(f"    {t}: {cnt} buildings, {a:.1f} m²")

print(f"\n  Building details:")
for _, row in gdf.iterrows():
    conf = 'HIGH' if row['id'] in [b['id'] for b in buildings if b.get('confidence') == 'high'] else \
           'MED' if row['id'] in [b['id'] for b in buildings if b.get('confidence') == 'medium'] else 'LOW'
    print(f"    ID={row['id']:>2d} | {row['name']:<45s} | {row['type']:<18s} | {row['size']:>8.1f} m² | conf={conf}")

print("\n" + "=" * 70)
print("DONE")
