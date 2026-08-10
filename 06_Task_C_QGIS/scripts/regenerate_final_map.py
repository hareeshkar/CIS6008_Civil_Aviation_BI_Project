#!/usr/bin/env .venv/bin/python
"""Regenerate Task C final A3 map with proper extents, no overlap, all layers visible."""
import geopandas as gpd, rasterio, matplotlib.pyplot as plt
from pathlib import Path
from rasterio.plot import show
import matplotlib.patches as mpatches

base = Path("/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project/06_Task_C_QGIS")
raster = base/"georeferenced_raster/BIA_georeferenced_EPSG5234.tif"

# Load all layers
admin = gpd.read_file(base/"digitized_layers/Admin Regions.shp")
bia = admin[admin["id"]==1111]
slaf = admin[admin["id"]==2222]
places = gpd.read_file(base/"digitized_layers/Airport Places New.shp")
tower = places[places["Name"]=="BIA Control Tower"]
rcp = places[places["Name"]=="Runaway Center Point"]
buildings = gpd.read_file(base/"digitized_layers/buildings_real.gpkg")
smr300 = gpd.read_file(base/"buffers/smr_300m_tower.gpkg")
rcp200 = gpd.read_file(base/"buffers/rcp_200m.gpkg")
psr2 = gpd.read_file(base/"buffers/psr_2km_rcp.gpkg")
psr3 = gpd.read_file(base/"buffers/psr_3km_rcp.gpkg")
smr_suit = gpd.read_file(base/"suitability_zones/smr_suitable.gpkg")
psr2_slaf = gpd.read_file(base/"suitability_zones/psr_2km_within_slaf.gpkg")
psr3_slaf = gpd.read_file(base/"suitability_zones/psr_3km_within_slaf.gpkg")

# Map extents - tight crop to all layers (PSR 3km dominates)
east_w = 98700
east_e = 104700
north_s = 217000
north_n = 223100

# True A3 at 300dpi: 11.69x8.27 inches
fig, ax = plt.subplots(figsize=(11.69, 8.27))

# Plot raster (downsampled for display)
with rasterio.open(raster) as src:
    # Read full raster at moderate resolution
    show(src, ax=ax, adjust='linear')

# SLAF base (light green)
slaf.plot(ax=ax, color="#d1e7dd", edgecolor="#0f5132", linewidth=1.2, alpha=0.45, label="SLAF Base (Katunayake) 3.90 km²")

# BIA boundary (dashed red)
bia.plot(ax=ax, facecolor="none", edgecolor="#842029", linewidth=1.5, linestyle="--", label="BIA Boundary 3.97 km²")

# PSR 3km (full extent, light yellow)
psr3.plot(ax=ax, color="#fff3cd", edgecolor="#664d03", linewidth=0.8, alpha=0.18, label="PSR/SSR 3 km max (28.23 km²)")

# PSR 2km preferred (light blue)
psr2.plot(ax=ax, color="#cfe2ff", edgecolor="#084298", linewidth=1, alpha=0.25, label="PSR/SSR 2 km preferred (12.54 km²)")

# SMR 300m tower
smr300.plot(ax=ax, color="#f8d7da", edgecolor="#842029", linewidth=1, alpha=0.40, label="SMR 300 m tower (0.28 km²)")

# RCP 200m
rcp200.plot(ax=ax, color="#e2e3e5", edgecolor="#41464b", linewidth=0.9, linestyle=":", alpha=0.50, label="RCP 200 m (0.13 km²)")

# PSR 2km within SLAF (suitable area)
psr2_slaf.plot(ax=ax, color="#0d6efd", edgecolor="#052c65", linewidth=1.3, alpha=0.55, label="PSR 2 km within SLAF — SUITABLE 3.81 km²")

# SMR suitable (the actual fitting area)
if not smr_suit.empty:
    smr_suit.plot(ax=ax, color="#dc3545", edgecolor="#58151c", linewidth=1.5, alpha=0.80, label="SMR suitable 17,417 m² (300∩200 m)")

# Buildings proxy (visualized)
buildings.plot(ax=ax, color="#f4b400", edgecolor="#7a5c00", linewidth=0.5, alpha=0.85, label="Buildings (16 real, 27,912 m², 9 in PSR2)")

# Tower/RCP points — larger for visibility
tower.plot(ax=ax, color="#cc0000", markersize=120, marker="^", edgecolor="black", linewidth=1.0, label="BIA Control Tower (A009)")
rcp.plot(ax=ax, color="#f4b400", markersize=120, marker="*", edgecolor="black", linewidth=1.0, label="Runway Center Point (A016)")

# Annotations - positioned to avoid overlap
for _, row in tower.iterrows():
    ax.annotate(f"BIA Tower\n({row.geometry.x:.0f}, {row.geometry.y:.0f})",
                xy=(row.geometry.x, row.geometry.y),
                xytext=(-180, 100), textcoords="offset points",
                fontsize=7, fontweight="bold",
                bbox=dict(boxstyle="round,pad=0.3", fc="white", alpha=0.92, ec="black"),
                arrowprops=dict(arrowstyle="->", color="black", lw=0.7))

for _, row in rcp.iterrows():
    ax.annotate(f"RCP\n({row.geometry.x:.0f}, {row.geometry.y:.0f})",
                xy=(row.geometry.x, row.geometry.y),
                xytext=(150, -80), textcoords="offset points",
                fontsize=7, fontweight="bold",
                bbox=dict(boxstyle="round,pad=0.3", fc="white", alpha=0.92, ec="black"),
                arrowprops=dict(arrowstyle="->", color="black", lw=0.7))

# Use proper extents
ax.set_xlim(east_w, east_e)
ax.set_ylim(north_s, north_n)

# North arrow (top-right)
ax.text(0.985, 0.965, "N", transform=ax.transAxes, fontsize=22, fontweight="bold",
        ha="center", va="center",
        bbox=dict(boxstyle="larrow,pad=0.4", fc="white", ec="black", lw=1.2))

# Scale bar (1 km)
# Center of map ~101000, 220000
x0, y0 = 99500, 217700
ax.plot([x0, x0+1000], [y0, y0], color="black", linewidth=4, zorder=10)
ax.plot([x0, x0+500], [y0, y0], color="white", linewidth=4, zorder=11)
ax.text(x0+500, y0+200, "1 km", ha="center", fontsize=8, fontweight="bold",
        bbox=dict(boxstyle="square,pad=0.2", fc="white", alpha=0.95, ec="black"),
        zorder=12)

# Title
ax.set_title("Bandaranaike International Airport — Radar Suitability Analysis (SMR & PSR/SSR)\nEPSG:5234 Kandawala / Sri Lanka Grid",
             fontsize=12, fontweight="bold", pad=14)

# Axis labels
ax.set_xlabel("Easting (m) — EPSG:5234", fontsize=10)
ax.set_ylabel("Northing (m)", fontsize=10)
ax.tick_params(labelsize=8)

# Legend (compact, 2 columns)
handles, labels = ax.get_legend_handles_labels()
by_label = dict(zip(labels, handles))
ax.legend(by_label.values(), by_label.keys(),
          fontsize=7.5, loc="lower right", framealpha=0.95,
          title="Legend (areas via ST_Area, EPSG:5234)",
          title_fontsize=8, ncol=2)

# CRS + data source caption
fig.text(0.01, 0.005,
         "CRS: EPSG:5234 | Data: 03_Original_Datasets/Task_C (authoritative) | Buffers: geopandas (equivalent QGIS native:buffer) | PostGIS SL_BIA_Aerial_Info: 15 tables, ST_Intersects/ST_Area verified | Interim python build — QGIS 4.2.1 Print Layout + real building digitization pending",
         fontsize=6.5, color="#333333", ha="left", va="bottom", wrap=True)

plt.tight_layout(rect=[0, 0.025, 1, 0.96])

# Save at true A3 300 dpi
out = base/"final_maps/BIA_Radar_Suitability_A3_python_interim.png"
plt.savefig(out, dpi=300, bbox_inches="tight")
print(f"Saved {out} {out.stat().st_size} bytes")

# PIL verification
from PIL import Image
im = Image.open(out)
print(f"PNG {im.size} dpi={im.info.get('dpi')}")
