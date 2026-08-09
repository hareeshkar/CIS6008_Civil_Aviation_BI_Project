# CIS6008 Assignment Criteria — Excellent Band Reference

> **Companion to `PROJECT_CONTEXT.md`.** Read both. This file translates the official marking rubric into what “Excellent (70-100)” actually demands, so agents generate evidence that meets it. Primary source: `01_Assignment_Brief/CIS6008_PRE1_Presentation_Brief.pdf` (PRE1, 20%, 10 pages, pdftotext-verified). WRIT1 practical weighting inferred (A30/B20/C30/D20) — note where inferred.

## 1. Two Assessments — What We Have

| Assessment | Weight | Source in Project | What It Assesses |
|---|---|---|---|
| **PRE1 — Business Proposal Presentation** | **20%** | `01_Assignment_Brief/CIS6008_PRE1_Presentation_Brief.pdf` (official) | Story + slides + verbal defence of statistical + geospatial BI for SL Civil Aviation (LO1). Mark out of 100 mapped to grade bands below. |
| **WRIT1 — Practical Portfolio** (inferred) | Remaining (likely 80%) | Inferred from `Task C guide.docx` + `Task C DB guide.docx` + `Task d Guide.docx` + 4 datasets (`Question-(a)..(d)`) | Hands-on: A regression (R), B network (R), C QGIS+PostGIS (maps+DB+calculations), D Power BI dashboard. Brief PDF not in folder — weighting 30/20/30/20 is the conventional split used across the RAR structure. **Flag:** If you locate a `WRIT1` brief PDF, merge it here. |

All descriptors below quote the official **Marking/Assessment Criteria table (pp. 7-8)**. Grade bands: **Poor <40, Satisfactory 40-49, Good 50-59, Very Good 60-69, Excellent 70-100.** Excellent is the target.

---

## 2. PRE1 — Six Criteria (Total 100) — What “Excellent” Means

### 2.1 Introduction to Topic & Relevance to Module/Matters (10 marks)

- **Poor:** not satisfactory, did not understand effective BA application.
- **Excellent (70-100):** *The introduction to the topic and the relevance to the module is excellent. The student has understood the effective application of business analytics to support the topic discussing matters excellent way.* (p.7)
- **Agent action:** Open presentation/report with 1-2 paragraphs linking CIS6008 LO1 (leading BI, predictive, geospatial, social analytics) to SL Civil Aviation (Ministry, BIA, foreign exchange, efficiency, sustainability). Name BA relevance explicitly; do not drift into generic aviation history.

### 2.2 Research Literature Review + Recognition of Statistical & Geospatial Software (15 marks)

- **Excellent:** *Student has done excellent research literature review relevant to the discussion. How clearly student has recognized various statistical and geospatial software applications available as open source or licensed in the market to support the discussion. The knowledge about latest statistical and GIS software applications also exhibited very well.* (p.8)
- **Agent action:**
  - Cite 10-15 credible sources (journals, ICAO, CAASL, Airbus/IATA forecasts) with Harvard in-text + reference list. Do not fabricate DOIs — only cite sources actually read (use `firecrawl_search`/`context7` and log URLs).
  - Create a **comparison table**: e.g., Statistical: `R (open, CRAN, tidyverse/lm/corrplot)`, `Python statsmodels`, `SPSS (licensed)`, `STATA`, `SAS`; Geospatial: `QGIS (open, EPSG:5234+, Processing)`, `ArcGIS (licensed)`, `PostGIS`, `GDAL/OGR`, `Google Earth`. Include open vs licensed, latest versions (verify via `context7_query-docs` — don’t guess). This table alone lifts Satisfactory → Excellent.

### 2.3 Importance of Topic per Global/Local Trends + Issues/Opportunities/Solutions/Feasibility (25 marks) — Highest Weight

- **Excellent:** *The student has discussed excellent way the importance of the topic as per global/local trends. Identification of the issues/opportunities and solutions related to the selected topic with the support of statistical, geospatial tools, technologies and methodologies. Feasibility of the proposal also has emphasized excellent way.* (p.8)
- **Agent action:**
  - Global: IATA passenger recovery, Asia-Pacific growth, radar/ATM modernization, GIS for airspace management.
  - Local (SL): tourism recovery, BIA congestion, MRIA underutilization, SLAF co-location, foreign exchange earnings, fuel/ATC constraints (use datasets A/B/D as local evidence).
  - Issues → Solutions mapping: each issue paired with a **tool-supported** solution + feasibility note (cost, data availability, skill, timeline). E.g., “Passenger demand forecasting uncertainty → Multiple regression (Task A, Adjusted R²=…) drives capacity planning; feasible: open-source R, 150-row training set, 2-week build.”
  - Never claim feasibility without referencing actual dataset/licensing/cost (e.g., “QGIS + PostGIS are open-source; BIA aerial already provided; no new flight purchases”).

### 2.4 Presentation Slides (20 marks)

- **Excellent:** *Clear and excellent precise presentation slides are developed excellent manner to aid the discussion of the topic. Very well developed logical story that the student leading the audience through. Slides contain required volume of information. Everything on the slide relevant to what student is explaining.* (p.7)
- **Agent action:**
  - 10-15 slides, theme consistent, no “glitz” animations. Fonts: **Title 30-40pt, Body 20-30pt, never <20pt** (p.5-6). High-contrast, readable at distance.
  - Logical arc: Title → Intro → Global/Local Trends → Issues → Methodology (Statistical+GIS tools table) → Task A findings (1-2 charts) → Task B network map → Task C suitability map → Integrated BI → Feasibility → Conclusions/Recommendations → References → Appendix.
  - Each slide: ≤6 bullets or 1 table/chart + caption; every visual captioned and Harvard-cited source.

### 2.5 Verbal Explanation & Presentation (20 marks)

- **Excellent:** *Student has verbally explained and presented the subject matter discussed in the presentation excellent manner without reading by looking at the slides either projected or printed. Student’s knowledge fluency of topic and business analytics subject domain is excellent. Student understand the study he/she is presenting very well. Student states the information he/she is presenting excellent way. Student is very well speaking clearly, loud enough, and making contact with the audience. Not mumbling, quiet, speaking into the screen, and hard to understand.* (pp.7-8)
- **Agent action:** Provide **speaker notes** (80-120 words/slide) in notes pane, not on slide. Include cue phrases, not scripts to read verbatim. Note timing (strict limits — practice).

### 2.6 Harvard Referencing & Citations (10 marks)

- **Excellent:** *The sources of information very well included. The Citations and Referencing done as per Harvard referencing system excellent way covering all major domains of the presentation.* (p.7)
- **Agent action:**
  - Cite in-text on each slide footer or adjacent to chart (“Source: IATA 2024; Air_Transport_Data.csv, Task A”).
  - Final slide: **References** Harvard (CiteThemRight) — journal article: Author Year, Title, Journal, Volume, pp. Authoritative web: Org Year, Title, URL, Accessed date.
  - Reference list excluded from word count (p.4) — include separately.

---

## 3. WRIT1 — Practical Tasks — Excellent Expectations (Inferred from Guides + Datasets)

Official WRIT1 brief PDF not in folder; expectations below synthesize the **lecturer guides** (which examiners actually mark against) and the **datasets’ required outputs**. Treat as provisional until a WRIT1 brief is found.

### 3.1 Task A — Regression (30)

- **Excellent evidence:** Clean R Markdown/`.R` that runs end-to-end (`Rscript scripts/task_a_regression.R`); `working_data/` copy preserves originals; descriptive table + Shapiro-Wilk table + correlation matrix + corrplot PNG + all scatterplots with regression lines + simple + multiple regression summaries (coefficients, SE, t, p, R²/Adj-R², F, AIC, VIF) + residual diagnostics (QQ, Scale-Location, Leverage) + business implications tying coefficients to demand planning (e.g., “+1 fuel_price unit → –X passenger_demand, ceteris paribus, p=…, suggests hedging”).
- **Failure modes:** Fabricated numbers, missing normality check, no VIF, no residual interpretation.

### 3.2 Task B — Network (20)

- **Excellent evidence:** `igraph` object built from edge list; metrics CSV with degree/betweenness/closeness/eigenvector per node sorted; identification of top 3 hubs + top 3 bridges with numbers; community detection (Louvain) table + color-coded graph PNG with weights; vulnerability paragraph (articulation points, what if CAASL or BIA node removed); resilience recommendations (redundancy, alternative routing via MRIA, coordination mechanisms). Export `.graphml`.

### 3.3 Task C — GIS + PostGIS (30) — Most Guide-Driven

- **Excellent evidence per `Task C guide.docx` / `Task C DB guide.docx`:**
  - Georeferenced raster (EPSG:5234) with GCP table + RMSE screenshot.
  - `SL_BIA_Aerial_Info` PostGIS DB: `\dt` screenshot, `CREATE EXTENSION postgis`, imported layers via `ogr2ogr -f PostgreSQL PG:"..."`.
  - Digitized layers (Buildings, Roads, Runways, Taxiways, Fence, Open Land, Water, Trees…) each with mandatory fields `id, name, type, size` — attribute table screenshots.
  - KML/KMZ round-trip: exported KML (EPSG:4326), opened in Google Earth, re-imported, centroids + `x($geometry)/y($geometry)` extracted.
  - **Buffer & overlay QA:** SMR 300m from tower + 200m from RCP (rings), PSR/SSR 2km preferred / 3km max from RCP, preferably inside SLAF base; `native:buffer`, `native:intersection`, `native:difference` screenshots + area attribute calcs; `ST_Intersects` building count, `SUM(ST_Area)` building area, available land = suitable area – building footprint.
  - Final map: professional Print Layout (title, legend, scale bar, north arrow, CRS 5234 note, data sources, date) as `final_maps/BIA_Radar_Suitability_A3.pdf` + `.qgz` + screenshot.

### 3.4 Task D — Power BI (20) — SKIPPED on Mac, but Criteria Documented

- From `Task d Guide.docx`: 3 pages (Executive Overview KPI cards, Delay Analysis, International Traffic by Country map), DAX examples (`Total Flights = COUNT(...)`, `CALCULATE(... Flight_Type="Arrival")`), slicers (Airline, Status, Weather, Terminal), weather/alert/bottleneck visuals. On Mac: deliver `cleaned_data` + `DAX_measures.md` + mock layout wireframe, note “to be built on Windows/Power BI Desktop” — do not claim a `.pbix` you didn’t build.

---

## 4. Grade Descriptors (Cardiff Met GBDs, per Academic Handbook Vol 1 §4.3, simplified p.9-10)

- **LO assessed:** *Demonstrate understanding of leading BI, data/predictive/geospatial analytics and apply them appropriately in real-world scenarios* (p.4). Demonstrated by running tools and interpreting — not describing.
- **EDGE skills:** Ethical (formal data handling), Digital (vector/raster, statistically significant processing), Global (global→local), Entrepreneurial (solution recommendations).
- **Word count:** 1000 equivalent (text+tables+figures+citations; references/appendices excluded) — keep report concise, push evidence to appendices with screenshots.
- **Unfair practice:** Plagiarism, collusion, fabrication of data/claims — includes inventing regression results, GIS counts, or citations (p.9). Zero tolerance.

---

## 5. How This Project Judges “Excellent”

An agent output is **Excellent** only if:
1. Every numeric claim traces to a file in `04/05/06/outputs` or `metrics/` + screenshot.
2. Every tool comparison cites a verified version/source (not guessed).
3. Feasibility explicitly ties to provided datasets/licensing/cost.
4. Harvard covers **all major domains** (at least one citation per section/slide).
5. Visuals are captioned, readable at 20pt+, and logically sequenced.
6. No `TODO`, placeholder, or “e.g., R²=0.85 (example)” — numbers are real or marked as to-run.

*Source trace: PDF pp. 2-8 via `pdftotext`; guides via `docx w:t` extraction (chars: C_guide 20490, C_DB 11235, D_Guide 20080). Flat files retained at root as provenance.*

