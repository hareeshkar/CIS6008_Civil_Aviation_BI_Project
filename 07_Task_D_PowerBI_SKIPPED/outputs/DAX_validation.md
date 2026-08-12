# DAX validation (live Power BI Desktop)

Source: connected to open `BIA_CMB` instance via modeling MCP (`localhost` XMLA).

## Unfiltered measures

| Measure | Result |
|---------|--------|
| Total Flights | 40 |
| Total Arrivals | 18 |
| Total Departures | 22 |
| Delayed Flights | 9 |
| On-Time Flights | 6 |
| Critical Alerts | 13 |
| Total Passengers | 8974 |
| Average Load Factor | 82.2 |
| Average Delay | 31.4 |
| Total Delayed Flights | 9 |
| Warning Alerts | 11 |

## Weather breakdown

| Weather_Condition | Flights | Passengers |
|-------------------|---------|------------|
| Clear | 9 | 2236 |
| Storm | 14 | 3044 |
| Rain | 7 | 1525 |
| Fog | 10 | 2169 |

## Destination Country (calculated column)

| Destination Country | Flights | Passengers |
|---------------------|---------|------------|
| Singapore | 9 | 2042 |
| Bangkok | 8 | 1764 |
| Doha | 6 | 1461 |
| Dubai | 7 | 1295 |
| Male | 4 | 1056 |
| London | 3 | 743 |
| Chennai | 3 | 613 |

Matches Executive Overview cards and International Traffic bars.
