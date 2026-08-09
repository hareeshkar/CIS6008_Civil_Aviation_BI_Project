# Decisions Log

## 2026-08-09 — Token-Efficient Stack Decision
- Chose Rscript CLI over R MCP for Tasks A+B (CLI 448 tokens vs MCP 61K). Installed via renv project-local.
- Chose duckdb CLI globally (single binary) over DuckDB MCP dual-mode.
- Chose qgis_process + GDAL CLI for geoprocessing (headless, reproducible). QGIS Agent MCP (gateway ~20 tokens) only justified MCP for interactive QGIS project/layout; nkarasiak/qgis-mcp as backup.
- Chose psql CLI over Postgres MCP initially (G/N <40% for this coursework). Will reconsider if DB phase becomes heavy.
- Skipped Power BI MCP on Mac — spec-only in 07_Task_D_PowerBI_SKIPPED/.

## 2026-08-09 — Global vs Project-Local Policy
- Global only: brew duckdb, qgis cask, gdal/apache-arrow, postgresql, unar (system binaries).
- Project-local: python .venv (pandas/geopandas etc.) + R renv per Task; QGIS MCP bridge via uvx socket per project.

## 2026-08-09 — Folder Structure
- Separate PROJECT_CONTEXT.md (scope) and ASSIGNMENT_CRITERIA.md (grading) per user request.
- Kept _RAR_Mirror inside 03_Original_Datasets for provenance; 99_TEMP is transient and will be cleaned after phase verification.

## 2026-08-09 — Read-Only Protection
- chmod 444 on all 03_Original_Datasets data files. Copy-before-transform enforced via AGENTS.md.
