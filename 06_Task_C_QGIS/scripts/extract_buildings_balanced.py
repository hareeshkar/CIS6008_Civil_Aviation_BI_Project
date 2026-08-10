"""
Balanced building extraction from RGB aerial imagery.
Tile-based + global polygonize — accuracy + speed + low RAM (16GB, TILE_SIZE=2048, HALO=32).
"""
import os
import math
import warnings
import numpy as np
import rasterio
from rasterio.enums import Resampling
from rasterio.features import shapes
from rasterio.windows import Window
import geopandas as gpd
from shapely.geometry import shape, Polygon, MultiPolygon
from shapely.validation import make_valid
from skimage import morphology, filters
warnings.filterwarnings("ignore")

PROJECT = "/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project"
RASTER = os.path.join(PROJECT, "06_Task_C_QGIS/georeferenced_raster/BIA_georeferenced_EPSG5234.tif")
OUTPUT_DIR = os.path.join(PROJECT, "06_Task_C_QGIS/outputs")
OUTPUT_GPKG = os.path.join(PROJECT, "06_Task_C_QGIS/digitized_layers/buildings_balanced.gpkg")
MASK_PATH = os.path.join(OUTPUT_DIR, "building_mask_balanced.tif")
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUTPUT_GPKG), exist_ok=True)

TILE_SIZE = 2048
HALO = 32
MAX_SAMPLE_PIXELS = 1_000_000
MIN_BRIGHTNESS = 100
MAX_BRIGHTNESS_THRESHOLD = 175
SHADOW_THRESHOLD = 35
GREEN_RED_THRESHOLD = 0.15
MORPH_MIN_AREA_M2 = 40
MAX_HOLE_AREA_M2 = 50
OPEN_RADIUS_PIXELS = 1
CLOSE_RADIUS_PIXELS = 1
MIN_BUILDING_AREA_M2 = 200
MAX_BUILDING_AREA_M2 = 8000
MIN_RECTANGULARITY = 0.40
MIN_SOLIDITY = 0.55
MAX_ASPECT_RATIO = 7.0

def normalize_band(array, low, high):
    array = array.astype(np.float32)
    denominator = max(high - low, 1e-6)
    array = (array - low) * (255.0 / denominator)
    return np.clip(array, 0, 255)

def expanded_window(core, raster_width, raster_height, halo):
    col0 = max(0, int(core.col_off) - halo)
    row0 = max(0, int(core.row_off) - halo)
    col1 = min(raster_width, int(core.col_off + core.width) + halo)
    row1 = min(raster_height, int(core.row_off + core.height) + halo)
    return Window(col_off=col0, row_off=row0, width=col1 - col0, height=row1 - row0)

def polygon_parts(geometry):
    if geometry is None or geometry.is_empty:
        return []
    if isinstance(geometry, Polygon):
        return [geometry]
    if isinstance(geometry, MultiPolygon):
        return list(geometry.geoms)
    if hasattr(geometry, "geoms"):
        return [geom for geom in geometry.geoms if isinstance(geom, Polygon)]
    return []

def oriented_geometry_metrics(poly):
    rectangle = poly.minimum_rotated_rectangle
    if rectangle.is_empty or rectangle.area <= 0:
        return None
    rectangularity = poly.area / rectangle.area
    convex_hull = poly.convex_hull
    if convex_hull.area <= 0:
        return None
    solidity = poly.area / convex_hull.area
    coords = list(rectangle.exterior.coords)
    if len(coords) < 5:
        return None
    side_lengths = []
    for i in range(4):
        x1, y1 = coords[i]
        x2, y2 = coords[i + 1]
        length = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
        side_lengths.append(length)
    longest = max(side_lengths)
    positive_sides = [length for length in side_lengths if length > 1e-6]
    if not positive_sides:
        return None
    shortest = min(positive_sides)
    aspect_ratio = longest / shortest
    return rectangularity, solidity, aspect_ratio

print("=" * 72)
print("BALANCED BUILDING FOOTPRINT EXTRACTION")
print("Accuracy + Speed + Low RAM — 16GB, TILE_SIZE=2048, HALO=32")
print("=" * 72)

print("\n[1/5] Inspecting raster...")
with rasterio.open(RASTER) as src:
    width = src.width
    height = src.height
    transform = src.transform
    crs = src.crs
    print(f"  Size: {width:,} x {height:,}")
    print(f"  CRS: {crs}")
    print(f"  Bands: {src.count}")
    print(f"  Data type: {src.dtypes}")
    if src.count < 3:
        raise RuntimeError("Raster must contain at least RGB bands.")
    if crs and crs.is_geographic:
        raise RuntimeError("Raster CRS is geographic. Reproject to metric first.")
    pixel_area = abs(transform.a * transform.e - transform.b * transform.d)
    pixel_size = math.sqrt(pixel_area)
    print(f"  Pixel area: {pixel_area:.4f} m²")
    print(f"  Approx pixel size: {pixel_size:.3f} m")

min_object_pixels = max(8, int(MORPH_MIN_AREA_M2 / pixel_area))
max_hole_pixels = max(8, int(MAX_HOLE_AREA_M2 / pixel_area))
print(f"  Morph minimum object: {min_object_pixels:,} pixels")
print(f"  Hole threshold: {max_hole_pixels:,} pixels")

print("\n[2/5] Estimating image statistics...")
with rasterio.open(RASTER) as src:
    total_pixels = width * height
    scale = min(1.0, math.sqrt(MAX_SAMPLE_PIXELS / total_pixels))
    sample_width = max(64, int(width * scale))
    sample_height = max(64, int(height * scale))
    print(f"  Sample size: {sample_width:,} x {sample_height:,}")
    sample = src.read([1, 2, 3], out_shape=(3, sample_height, sample_width), resampling=Resampling.bilinear)

band_low = []
band_high = []
for band in sample:
    valid = band[np.isfinite(band)]
    low = np.percentile(valid, 2)
    high = np.percentile(valid, 98)
    band_low.append(low)
    band_high.append(high)

r = normalize_band(sample[0], band_low[0], band_high[0])
g = normalize_band(sample[1], band_low[1], band_high[1])
b = normalize_band(sample[2], band_low[2], band_high[2])
gray = (0.2989 * r + 0.5870 * g + 0.1140 * b)
green_red_index = (g - r) / (g + r + 1e-6)
shadow = gray < SHADOW_THRESHOLD
vegetation = ((green_red_index > GREEN_RED_THRESHOLD) | ((g > r * 1.25) & (g > b * 1.10) & (gray < 170)))
valid_for_threshold = (~shadow & ~vegetation)
threshold_values = gray[valid_for_threshold]
if threshold_values.size > 1000:
    otsu_threshold = filters.threshold_otsu(threshold_values)
else:
    otsu_threshold = MIN_BRIGHTNESS
brightness_threshold = float(np.clip(otsu_threshold, MIN_BRIGHTNESS, MAX_BRIGHTNESS_THRESHOLD))
print(f"  Otsu threshold: {otsu_threshold:.1f}")
print(f"  Final brightness threshold: {brightness_threshold:.1f}")
print(f"  Estimated vegetation: {vegetation.mean() * 100:.1f}%")
print(f"  Estimated shadow: {shadow.mean() * 100:.1f}%")
del sample, r, g, b, gray, vegetation, shadow, green_red_index, threshold_values

print("\n[3/5] Creating building candidate mask...")
with rasterio.open(RASTER) as src:
    profile = src.profile.copy()
    profile.update(driver="GTiff", count=1, dtype="uint8", nodata=0, compress="DEFLATE", predictor=1, tiled=True, blockxsize=512, blockysize=512, BIGTIFF="IF_SAFER")
    number_x = math.ceil(width / TILE_SIZE)
    number_y = math.ceil(height / TILE_SIZE)
    total_tiles = number_x * number_y
    tile_counter = 0
    with rasterio.open(MASK_PATH, "w", **profile) as dst:
        for row in range(0, height, TILE_SIZE):
            for col in range(0, width, TILE_SIZE):
                core_width = min(TILE_SIZE, width - col)
                core_height = min(TILE_SIZE, height - row)
                core = Window(col, row, core_width, core_height)
                ext = expanded_window(core, width, height, HALO)
                rgb = src.read([1, 2, 3], window=ext)
                r = normalize_band(rgb[0], band_low[0], band_high[0])
                g = normalize_band(rgb[1], band_low[1], band_high[1])
                b = normalize_band(rgb[2], band_low[2], band_high[2])
                gray = (0.2989 * r + 0.5870 * g + 0.1140 * b)
                green_red_index = (g - r) / (g + r + 1e-6)
                vegetation = ((green_red_index > GREEN_RED_THRESHOLD) | ((g > r * 1.25) & (g > b * 1.10) & (gray < 170)))
                shadow = (gray < SHADOW_THRESHOLD)
                candidate = ((gray > brightness_threshold) & ~vegetation & ~shadow)
                candidate = morphology.remove_small_objects(candidate, min_size=min_object_pixels)
                if OPEN_RADIUS_PIXELS > 0:
                    candidate = morphology.opening(candidate, morphology.disk(OPEN_RADIUS_PIXELS))
                if CLOSE_RADIUS_PIXELS > 0:
                    candidate = morphology.closing(candidate, morphology.disk(CLOSE_RADIUS_PIXELS))
                candidate = morphology.remove_small_holes(candidate, area_threshold=max_hole_pixels)
                row_start = int(core.row_off - ext.row_off)
                col_start = int(core.col_off - ext.col_off)
                row_end = row_start + int(core.height)
                col_end = col_start + int(core.width)
                core_mask = candidate[row_start:row_end, col_start:col_end]
                dst.write(core_mask.astype(np.uint8), 1, window=core)
                tile_counter += 1
                if (tile_counter % 10 == 0 or tile_counter == total_tiles):
                    percent = 100 * tile_counter / total_tiles
                    print(f"  Tiles: {tile_counter}/{total_tiles} ({percent:.1f}%)")
print(f"\n  Mask written: {MASK_PATH}")

print("\n[4/5] Polygonizing and filtering...")
records = []
candidate_count = 0
accepted_count = 0
with rasterio.open(MASK_PATH) as mask_src:
    mask_band = rasterio.band(mask_src, 1)
    polygons = shapes(mask_band, transform=mask_src.transform, connectivity=8)
    for geom, value in polygons:
        if int(value) != 1:
            continue
        candidate_count += 1
        poly = shape(geom)
        if poly.is_empty:
            continue
        if not poly.is_valid:
            poly = make_valid(poly)
        for part in polygon_parts(poly):
            if part.is_empty:
                continue
            area = part.area
            if area < MIN_BUILDING_AREA_M2:
                continue
            if area > MAX_BUILDING_AREA_M2:
                continue
            simplify_tolerance = (pixel_size * 0.50)
            simplified = part.simplify(simplify_tolerance, preserve_topology=True)
            if simplified.is_empty:
                continue
            if not simplified.is_valid:
                simplified = make_valid(simplified)
            simplified_parts = polygon_parts(simplified)
            if not simplified_parts:
                continue
            for final_poly in simplified_parts:
                final_area = final_poly.area
                if (final_area < MIN_BUILDING_AREA_M2 or final_area > MAX_BUILDING_AREA_M2):
                    continue
                metrics = oriented_geometry_metrics(final_poly)
                if metrics is None:
                    continue
                (rectangularity, solidity, aspect_ratio) = metrics
                if (rectangularity < MIN_RECTANGULARITY):
                    continue
                if (solidity < MIN_SOLIDITY):
                    continue
                if (aspect_ratio > MAX_ASPECT_RATIO):
                    continue
                accepted_count += 1
                records.append({
                    "id": accepted_count,
                    "name": f"Building {accepted_count}",
                    "type": "Building",
                    "size_m2": round(final_area, 2),
                    "rectangularity": round(rectangularity, 3),
                    "solidity": round(solidity, 3),
                    "aspect_ratio": round(aspect_ratio, 2),
                    "geometry": final_poly,
                })
print(f"  Candidate polygons: {candidate_count:,}")
print(f"  Accepted buildings: {accepted_count:,}")

print("\n[5/5] Saving GeoPackage...")
if records:
    gdf = gpd.GeoDataFrame(records, geometry="geometry", crs=crs)
    gdf = gdf.sort_values("size_m2", ascending=False).reset_index(drop=True)
    gdf["id"] = (np.arange(len(gdf)) + 1)
    gdf["name"] = ("Building " + gdf["id"].astype(str))
    if os.path.exists(OUTPUT_GPKG):
        os.remove(OUTPUT_GPKG)
    gdf.to_file(OUTPUT_GPKG, driver="GPKG", layer="buildings")
    total_area = gdf["size_m2"].sum()
    print(f"\n  Buildings: {len(gdf):,}")
    print(f"  Total footprint area: {total_area:,.1f} m²")
    print(f"  Mean footprint area: {gdf['size_m2'].mean():,.1f} m²")
    print(f"  Median footprint area: {gdf['size_m2'].median():,.1f} m²")
    print(f"\n  GeoPackage:\n  {OUTPUT_GPKG}")
else:
    print("\nWARNING: No buildings passed the extraction filters.")
    print("Try lowering MIN_BRIGHTNESS or MIN_RECTANGULARITY.")

print("\n" + "=" * 72)
print("DONE")
print("=" * 72)
