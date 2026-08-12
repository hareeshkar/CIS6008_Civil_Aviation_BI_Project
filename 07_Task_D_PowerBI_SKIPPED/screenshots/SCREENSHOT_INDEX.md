# Task D — Fresh Visual Evidence Index

Captured live from Power BI Desktop (`BIA_CMB` open as PBIP).  
No report edits during capture. Validated against live DAX queries on `localhost` Analysis Services.

## Files

| File | What it shows | Validation (live DAX) |
|------|----------------|------------------------|
| `01_Executive_Overview.png` | Page 1 — 8 KPI cards + status donut + arrival/departure + alert + runway | Total Flights **40**, Arrivals **18**, Departures **22**, Delayed **9**, On-Time **6**, Critical **13**, Passengers **8974**, Avg Load Factor **82.2** |
| `02_Delay_Analysis.png` | Page 2 — avg delay, delayed flights, warning alerts, top delays, delay by airline, cause pie, weather, wind scatter | Average Delay **31.4**, Total Delayed Flights **9**, Warning Alerts **11** |
| `03_International_Traffic.png` | Page 3 default — map, passenger by destination, SMR donut, queue scatter, flight table, slicers | Destinations ranked by pax: Singapore **2042**, Bangkok **1764**, Doha **1461**, Dubai **1295**, Male **1056**, London **743**, Chennai **613** |
| `04_Page3_Weather_Clear.png` | Page 3 with **Weather_Condition = Clear** selected (slicer) | Clear weather: **9** flights, **2236** passengers (Storm 14/3044, Rain 7/1525, Fog 10/2169) |
| `06_TableView_CleanedData.png` | Table view of imported `BIA_CMB` cleaned rows (Flight_ID, Airline, Route, times, gate, terminal, runway, status, delay, …) | 40 source rows loaded; columns typed (Delay_Minutes int, etc.) |

## Live KPI proof (DAX, Power BI Desktop session)

```
Total Flights          40
Total Arrivals         18
Total Departures       22
Delayed Flights         9
On-Time Flights         6
Critical Alerts        13
Total Passengers     8974
Average Load Factor  82.2
Average Delay        31.4
Total Delayed Flights   9
Warning Alerts         11
```

## Weather filter proof (for Page 3 slicer evidence)

| Weather | Flights | Passengers |
|---------|---------|------------|
| Clear | 9 | 2236 |
| Storm | 14 | 3044 |
| Rain | 7 | 1525 |
| Fog | 10 | 2169 |

## Notes for report writing later

- Page 1 cards match guide KPI set (Total Flights through Average Load Factor).
- Page 2 shows delay analytics (airline, issue type, weather, wind scatter).
- Page 3 shows international map + destination traffic + radar/ops visuals + slicers (Airline, Weather, Alert).
- Table view proves cleaned CSV import (not empty structure).
- Multi-airline / multi-alert slicer automation was blocked by DPI hit-testing; **Weather = Clear** is the captured multi-option slicer state. Additional airline/alert combos can be re-captured manually in one click if markers need them.

## Paths

- Screenshots: `07_Task_D_PowerBI_SKIPPED/screenshots/`
- PBIP: `07_Task_D_PowerBI_SKIPPED/pbip/BIA_CMB.pbip`
- PBIX: `C:\Users\hirus\Desktop\BIA_CMB.pbix`
- Clean CSV: `07_Task_D_PowerBI_SKIPPED/cleaned_data/BIA_CMB_clean.csv`
