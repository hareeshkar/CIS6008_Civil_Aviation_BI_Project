# Software Notes — Token-Efficient CLI vs MCP (Mac M4)

> Why this project uses CLI everywhere and MCP only once. Numbers from 2026 benchmarks; see citations at end.

## 1. The Core Insight: Token Cost

- **CLI:** ~**200 tokens** per command. Zero fixed overhead per prompt. Agent formats a string, runs it, parses stdout.
- **MCP:** **32K-82K tokens** per operation when full tool schema is loaded; typical MCP session loads upfront. Gateways moderate it to ~**892 tokens** (2× CLI) but native MCP (e.g., GitHub MCP) hits **61K tokens = 137× CLI** (Firecrawl 2026, Scalekit 2026). Fixed overhead per prompt for native MCP: **~3,062 tokens even before a tool call** (blog.mornati.net).
- **Reliability:** CLI 100% vs MCP 72% as task complexity rises (Scalekit benchmark: MCP 35× more tokens, lower success).
- **Where MCP wins back:** Multi-step tasks with shared session state — MCP persists context, CLI re-prompts each call. Crossover is task depth: for 1-3 calls, CLI dominates; for deep interactive sessions against the same service, gateway MCP amortizes.

Bottom line for CIS6008: **Use CLI for execution, skill/markdown for guidance, MCP only for interactive QGIS project manipulation where no CLI equivalent exists.**

## 2. Per-Task Decision — Token-Efficient Stack

### Task A+B — Statistical / Network

| Choice | Rationale | Install |
|---|---|---|
| `Rscript` CLI | Already present (R 4.5.2), runs any `.R` deterministically, loggable. R MCP would load 50+ tool schemas for no gain (G/N <5% — rare use). | `Rscript` global; packages **project-local** via `renv` (see §4). Packages: A=`tidyverse,car,lmtest,corrplot,ggplot2,psych`; B=`igraph,tidygraph,ggraph`. |
| `duckdb` CLI for quick CSV probe | Lets agent inspect any CSV with SQL without writing R: `duckdb : "SELECT * FROM read_csv_auto(...)"`. DuckDB MCP (dual mode) is heavier and unnecessary. | `brew install duckdb` — **global binary** (single executable, <50M, amortized across tasks). |

### Task C — GIS + DB

| Choice | Rationale | Install |
|---|---|---|
| `GDAL/OGR` CLI (`gdalinfo`, `ogrinfo`, `ogr2ogr`, `gdalwarp`) | Translator library for raster+vector; no MCP needed; essential for inspecting the 94M `.tif` and KML↔GPKG conversion. | `brew` global (`gdal`); currently broken due to `libarrow_dataset` — fix via `brew reinstall apache-arrow gdal`. |
| `qgis_process` CLI | Headless QGIS processing framework — exposes `native:buffer`, `native:intersection`, `native:difference`, `native:centroids` etc. as deterministic commands. Community consensus (r/gis 2026): headless QGIS via CLI is the most agent-reliable GIS path. | Ships with `QGIS.app`; requires `brew install --cask qgis` globally (1.1G app). |
| `psql` CLI + PostGIS | Local DB small, single-user; `psql` is lowest-token DB client. Postgres MCP (gateway ~20 tokens, native ~3K) only justified if G/N >40% (mornati G/N matrix). For this coursework session is not DB-heavy — CLI wins. | `postgresql@18` already global (`/opt/homebrew/bin/psql 18.3`). No MCP now; reconsider only if we add a data-heavy assurance phase. |
| `QGIS Agent MCP` (small-context, gateway) | **The one justified MCP.** Task C requires *interactive* QGIS project inspection: load raster, manage layers, print layouts — no CLI for that. QGIS Agent MCP keeps tool context ~**20 tokens** (vs native 3K) by dynamically exposing tools instead of dumping all 100+ tools upfront (Reddit r/QGIS 2026, qgis-mcp GitHub). | **Project-local:** QGIS plugin `qgis_mcp` / `qgis_agent_mcp` enabled inside `06_Task_C_QGIS/` + `uvx` socket on 9876. Not a global MCP server registration. Backup: `nkarasiak/qgis-mcp` (50-100 tools) if Agent MCP misses a tool — but it’s higher overhead. |

### Task D — Power BI

| Choice | Rationale | Install |
|---|---|---|
| **Skip MCP, skip Desktop on Mac** | Official Power BI MCP (remote/local, Microsoft Learn 2026) requires Windows + semantic model permissions + Node/VS Code local MCP. On Mac it doesn’t make Desktop native. Best path is Mac prepares `cleaned_data` + `DAX_measures.md` (from `Task d Guide.docx` samples) → Windows builds `.pbix` later. | No install on Mac. Leave `07_Task_D_PowerBI_SKIPPED/` as spec-only. |

## 3. Global vs Project-Local Policy (Per User Instruction)

- **Global only if unavoidable binary/app:** `duckdb`, `qgis` (provides `qgis_process`), `gdal`/`apache-arrow`, `postgresql`, `unar`. These live in `/opt/homebrew/` and are single-version system tools.
- **Project-local everything else:**
  - Python: `python3 -m venv .venv` inside project root → `pip install pandas geopandas duckdb psycopg2-binary openpyxl pypdf pdfminer.six` (never `sudo pip` or global `pip`).
  - R: `renv::init()` → `renv.lock` per `04_Task_A_R_Regression/` and `05_Task_B_Network_Analysis/` (isolated library `renv/library/`).
  - QGIS MCP bridge: `uvx` / plugin configured per `06_Task_C_QGIS/qgis_project/` (not `~/.config/mcp`).
  - Node: no global `npm -g` for this project.

## 4. Setup Commands (Project-Local)

```bash
# Python venv (project root)
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install pandas geopandas pyarrow shapely psycopg2-binary duckdb openpyxl pypdf pdfminer.six

# R renv — run inside each Task folder
Rscript -e 'if (!requireNamespace("renv", quietly=TRUE)) install.packages("renv"); setwd("04_Task_A_R_Regression"); renv::init(bare=TRUE); renv::install(c("tidyverse","car","lmtest","corrplot","ggplot2","psych"))'
Rscript -e 'setwd("05_Task_B_Network_Analysis"); renv::init(bare=TRUE); renv::install(c("igraph","tidygraph","ggraph"))'

# Global binaries (only if missing)
brew install duckdb
brew install --cask qgis   # provides qgis_process + GDAL bundle
brew reinstall apache-arrow gdal  # fix libarrow_dataset
```

## 5. Verification (What Agent Must Run)

```bash
Rscript --version
duckdb --version
psql --version && psql -c "SELECT version()"
gdalinfo --version && ogrinfo --version
qgis_process --help 2>&1 | head -n 20
psql -d SL_BIA_Aerial_Info -c "SELECT PostGIS_version()"
```

Log all versions to `12_AGENT_LOGS/commands_used.md` at start of each task phase.

## 6. When to Reconsider MCP

- If DB assurance phase becomes query-heavy (dozens of spatial SQL calls in a row), add **Postgres gateway MCP** (~20 tokens overhead) — cheaper than re-prompting schema each `psql` call.
- If QGIS interactive layout editing exceeds 10 round-trips, keep Agent MCP (already gateway) — don’t “upgrade” to native.

## 7. Unrecommended (For This Project)

- **R MCP, DuckDB MCP Extension (client/server), Power BI MCP (remote/local), native Postgres MCP** — token overhead 22-137× for no net capability on Mac M4 for this scope.
- `mcp2cli` (2.2K stars, claims 96-99% token savings) is interesting generically but adds a proxy layer we don’t need when native CLIs already exist.

---

**Sources:** Firecrawl “MCP vs CLI for AI Agents 2026” (~200 vs 44K tokens, 61K GitHub MCP 137×); blog.mornati.net “MCP vs CLI: Measuring Real Token Cost” (CLI 448 vs MCP 3,062 fixed, G/N thresholds); devops-daily “CLI vs MCP” (35× gap, 72% reliability); Reddit r/QGIS “QGIS Agent MCP keeps context small” + r/gis “headless QGIS via qgis_process” ; GitHub `nkarasiak/qgis-mcp` (50-100 tools) vs QGIS Agent MCP (dynamic, ~20 tokens); Microsoft Learn “Power BI MCP servers” (remote requires semantic model permissions, local requires Windows/VS Code).

*Last verified: 2026-08-09 via firecrawl_search (4 queries) + local `Rscript --version`, `psql --version`, `brew info`.*
