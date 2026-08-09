# 03_Original_Datasets — Master Copy (READ-ONLY)

**Do not edit files in this folder.** This is the master copy from `ABI-CIS6008-SEP-2026-Dataset - Final.rar`.

## Structure
- `Task_A/Air_Transport_Data.csv` (25K) + `Air_Transportation_Data_Dictionary.docx` — regression: passenger_demand ~ airport_traffic, avg_income, fuel_price, avg_ticket_fare, flight_frequency, route_distance
- `Task_B/SriLanka_Aviation_SNA_Dataset.csv` (1.8K) — edges: Source, Target, Relationship, Weight
- `Task_C/Raster/Bandaranayake Airport Areal Latest3_1_modified.tif` (94M) — aerial image to georeference EPSG:5234
- `Task_C/Shapefiles/` — Admin Regions, Air Force Base Katunayake, Air Force Base Region, Airport Places, Airport Places New (.shp/.shx/.dbf/.prj/.cpg/.qmd)
- `Task_C/KML_KMZ/Airport Places.kml` (9.4K) — Google Earth import
- `Task_D/BIA_CMB_Dataset.csv` (7.5K) + `BIA_CMB_Data_Dictionary.pdf` — flight ops, delays, weather, alerts (Power BI — SKIPPED on Mac)
- `_RAR_Mirror/` — exact extracted tree for provenance

## Rule
Copy before transforming:
`03_Original_Datasets/Task_A/Air_Transport_Data.csv` → `04_Task_A_R_Regression/working_data/Air_Transport_Data_clean.csv`
