# DAX Measures & Calculated Column — Task D Power BI

> Source: `01_Assignment_Brief/Task_D_PowerBI_Guide.docx` (lecturer spec) mirrored in the
> semantic model of the PBIP project `pbip/BIA_CMB.pbip`.
> All measures are implemented in the model via the `powerbi-modeling` MCP and validated by DAX queries
> against the live Power BI Desktop instance (see `outputs/DAX_validation.md`).

## Table & Calculated Column

| Object | DAX |
|---|---|
| Table | `BIA_CMB` (fact table, 40 rows × 28 columns imported from `cleaned_data/BIA_CMB_clean.csv` via M/Power Query) |
| `Destination Country` (calculated column) | `RIGHT('BIA_CMB'[Route], LEN('BIA_CMB'[Route]) - FIND("-", 'BIA_CMB'[Route], 1))` |

The `Destination Country` column is intentionally created as a DAX **calculated column** (guide Step 1)
and is therefore NOT present in the CSV — it derives `Singapore`, `Dubai`, `Doha`, `London`, `Bangkok`,
`Male`, `Chennai` from the `Route` values at load time.

## Page 1 — Executive Overview KPIs

| Measure | DAX Expression |
|---|---|
| Total Flights | `COUNT('BIA_CMB'[Flight_ID])` |
| Total Arrivals | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Flight_Type] = "Arrival")` |
| Total Departures | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Flight_Type] = "Departure")` |
| Delayed Flights | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Status] = "Delayed")` |
| On-Time Flights | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Status] = "On Time")` |
| Critical Alerts | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Alert_Status] = "Critical")` |
| Total Passengers | `SUM('BIA_CMB'[Passenger_Count])` |
| Average Load Factor | `AVERAGE('BIA_CMB'[Load_Factor_%])` |

## Page 2 — Delay Analysis KPIs

| Measure | DAX Expression |
|---|---|
| Average Delay | `AVERAGE('BIA_CMB'[Delay_Minutes])` |
| Total Delayed Flights | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Status] = "Delayed")` |
| Warning Alerts | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Alert_Status] = "Warning")` |
| Normal Alerts | `CALCULATE(COUNT('BIA_CMB'[Flight_ID]), 'BIA_CMB'[Alert_Status] = "Normal")` |

## Report Pages & Visuals (per guide)

### Page 1 — Executive Overview
- KPI cards: Total Flights, Total Arrivals, Total Departures, Delayed Flights, On-Time Flights,
  Critical Alerts, Total Passengers, Average Load Factor
- Donut: Flight Status Distribution (`Status` legend, `Count(Flight_ID)`)
- Clustered Column: Arrival vs Departure (`Flight_Type`, `Count(Flight_ID)`)
- Donut: Alert Status Distribution (`Alert_Status`, `Count(Flight_ID)`)
- Clustered Column: Runway Utilization (`Runway`, `Count(Flight_ID)`)

### Page 2 — Delay Analysis
- KPI cards: Average Delay, Total Delayed Flights, Warning Alerts
- Clustered Bar: Top Delayed Flights (`Flight_ID`, `Sum(Delay_Minutes)`)
- Clustered Bar: Delay by Airline (`Airline`, `Sum(Delay_Minutes)`)
- Pie: Delay Cause Analysis (`Issue_Type`, `Count(Flight_ID)`)
- Clustered Column: Delay vs Weather (`Weather_Condition`, `Avg(Delay_Minutes)`)
- Scatter: Wind Speed vs Delay (`Wind_Speed_kmh` × `Delay_Minutes`, bubble `Passenger_Count`, colour `Alert_Status`)

### Page 3 — International Traffic
- Map: Traffic by Country (`Destination Country` location, bubble `Count(Flight_ID)`)
- Clustered Bar: Passenger Traffic by Destination (`Destination Country`, `Sum(Passenger_Count)`)
- Donut: Aircraft Location Distribution (`SMR_Location`, `Count(Flight_ID)`)
- Scatter: Queue Position vs Taxi Time (`Queue_Position` × `Taxi_Time`, bubble `Passenger_Count`)
- Table: Flight Operations (`Flight_ID, Airline, Route, Delay_Minutes, Issue_Type, Alert_Status`)
- Slicers: Airline, Weather, Alert Status

## Power Query (M) Data Load

The table is loaded by M with explicit type coercion so measures sum/average numeric columns correctly:

```m
let
    Source = Csv.Document(File.Contents("...\cleaned_data\BIA_CMB_clean.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{
        {"Scheduled_Time", type datetime},{"Estimated_Time", type datetime},
        {"Gate", Int64.Type},{"Delay_Minutes", Int64.Type},{"Aircraft_Capacity", Int64.Type},
        {"Temperature_C", Int64.Type},{"Wind_Speed_kmh", Int64.Type},
        {"Turnaround_Time", Int64.Type},{"Taxi_Time", Int64.Type},{"Queue_Position", Int64.Type},
        {"Passenger_Count", Int64.Type},{"Load_Factor_%", type number}})
in
    #"Changed Type"
```
