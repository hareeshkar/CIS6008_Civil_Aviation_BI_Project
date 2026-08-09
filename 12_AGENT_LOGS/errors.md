# Errors & Fixes

## 2026-08-09 — gdalinfo broken
- `gdalinfo --version` failed: `Library not loaded: .../libarrow_dataset.2400.dylib` — GDAL 3.13.1_3 linked against old apache-arrow. Fix pending: `brew reinstall apache-arrow gdal` (global).

## 2026-08-09 — Missing binaries
- duckdb not found (brew not yet installed)
- qgis_process not found (QGIS cask not yet installed)
- unar not found — fixed via `brew install unar`

## 2026-08-09 — Postgres start failure (Tahoe)
- `brew services start postgresql@18` succeeded but `pg_isready` fails — `postgres` binary dyld error `libicui18n.78.dylib` not found. Tahoe 27 is not Tier 1 for Homebrew (brew warning). Fix before Task C DB: `brew reinstall icu4c@78 icu4c postgresql@18 && brew services restart postgresql@18` or pin to `postgresql@17` if 18 remains broken. Will test `CREATE EXTENSION postgis` after fix.
- Similarly `gdal` broken on `libarrow_dataset.2400.dylib` — same Tahoe/Homebrew arrow 25.0.0_3 download interrupted (SIGTERM). Need reinstall; defer to Task C GIS phase where needed.

## 2026-08-09 — R renv
- renv bare init succeeded for both Task A and Task B; 132 and 112 packages linked from cache respectively. No errors.
