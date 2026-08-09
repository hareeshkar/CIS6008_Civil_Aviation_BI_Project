# Agent Actions Log

Append every major operation here with date + summary + files touched.

## 2026-08-09 — Project Skeleton + Core Markdown Files Created
- Created full folder structure 00_READ_ME through 12_AGENT_LOGS, 99_TEMP per spec
- Copied briefs/guides from flat root into 01_Assignment_Brief + 02_Lecturer_Guides
- Extracted ABI-CIS6008-SEP-2026-Dataset - Final.rar (67M, 40 entries) via unar/bsdtar to 99_TEMP/rar_extract then organized into 03_Original_Datasets/Task_{A,B,C,D}
- Set chmod 444 on all 03_Original_Datasets data files (read-only master copy)
- Created 00_READ_ME/PROJECT_CONTEXT.md (8 sections, tool mapping, folder tree)
- Created 00_READ_ME/ASSIGNMENT_CRITERIA.md (PRE1 6 criteria excellent band + WRIT1 inferred expectations)
- Created 00_READ_ME/TASK_CHECKLIST.md (A/B/C/D checkboxes) + 00_READ_ME/SOFTWARE_NOTES.md (CLI vs MCP benchmarks) + AGENTS.md root contract
- Next: project-local .venv + renv + global duckdb/gdal fix + toolchain verify

## 2026-08-09 — Venv + Toolchain + Clean TEMP
- Created project-local .venv (Python 3.11.14, pandas 3.0.5, duckdb 1.5.5, psycopg2-binary 2.9.12) — no global pip installs
- Installed R packages corrplot, psych, igraph, tidygraph, ggraph (now all TRUE) and initialized renv for Task A (132 pkg) + Task B (112 pkg) with lockfiles
- Installed duckdb 1.5.5 globally (brew) — global binary justified
- Attempted GDAL/arrow reinstall — failed due to Tahoe pre-release brew SIGTERM; logged as deferred to Task C phase
- Verified postgres@18 binary 18.3 present but server fails on icu4c@78 missing (Tahoe); logged defer
- Verified CSV row counts via venv duckdb: A=200, B=28, D=40
- Cleaned 99_TEMP/rar_extract (97M) after confirming all files present in 03_Original_Datasets + _RAR_Mirror; left .keep

## 2026-08-09 — Task A Executed
- Script: `04_Task_A_R_Regression/scripts/task_a_regression.R` (10 steps: load/inspect/descriptive/normality/correlation/scatter/simple/multiple/diagnostics/export) — renv-aware, copy-before-transform verified
- Run: `Rscript 04_Task_A_R_Regression/scripts/task_a_regression.R` — success (n=200, 0 missing, all normal, VIF~1.05, BP p=0.56, DW 2.07)
- Outputs: 15 files in outputs/ (descriptive_statistics.csv, correlation_matrix.csv, normality_tests.csv, simple_regression_results.csv, multiple_regression_summary.txt: R²=0.1789 Adj 0.1534 F=7.008 p=9.27e-07) + 7 in tables/ + 28 PNGs in plots/ (6 scatter + 7 hist + 8 qq + correlation + diagnostics)
- Key finding: airport_traffic r=0.385 R² 0.1485 p=1.75e-8 dominant; multiple retains airport_traffic*** + fuel_price* (positive artefact); 5 IVs ns; low explanatory power (~15% adj)
- Created `04_Task_A_R_Regression/outputs/TASK_A_FINDINGS.md` from actual outputs (no fabrication) — answers 4 questions with traceable file references
- Verified against validator map: all expected PNGs/CSVs present

## 2026-08-09 — Task A Validation (Sub-Region Audit)
- Allocated Task A as sub-region, inherited same OLS model (no re-estimation)
- Launched explore subagent audit (16 outputs, 34 plots, 7 tables) — verdict: 10/10 PASS, no fabrication, 3 minor cosmetics
- Analyzed every PNG via .venv Pillow: 34/34 readable, 1800-2400px, 70-413KB, no corruption; inspected each hist/qq/scatter/corr/diagnostic qualitatively
- Fixed model_comparison.csv 9→8 rows (deparse newline bug) and propagated to tables/; patched script to use paste formula + iv_units labels
- Generated screenshots/sessionInfo.txt:1 (R 4.5.2 + pkg versions) + terminal_run_log_2026-08-09.txt:1 to close evidence gap
- Created outputs/TASK_A_VALIDATION_REPORT.md:1 — full per-file/per-image analysis, assignment compliance matrix, re-verification vs python duckdb

## 2026-08-09 — AGENTS.md Updated for Mandatory Sub-Agent Review
- Added §10 Mandatory Validation — spawn sub-agent reviewer after each task (A/B/C/D-spec)
- Rule: no task done until outputs/TASK_X_VALIDATION_REPORT.md exists
- Template prompt enforces: inherit same model, test against PROJECT_CONTEXT + ASSIGNMENT_CRITERIA, stat every file, recompute spot stats, open every PNG via Pillow, check TASK_CHECKLIST PASS/FAIL, return structured report
- Reference exemplar: 04_Task_A_R_Regression/outputs/TASK_A_VALIDATION_REPORT.md:1 (Task A flow on 2026-08-09)
- Upcoming Tasks B/C must reuse identical workflow

## 2026-08-09 — Task B Completed + Enhanced Visuals + GitHub
- Completed Task B network analysis: 15 nodes 28 edges, density 0.133, Louvain 4 mod 0.33, Cargo 7 deg, Fuel 12 betweenness
- Fixed edge direction bug (tail_of/head_of swap) and re-verified via duckdb R igraph; fixed degree_distribution geom_text bug; GML via networkx fallback; FINDINGS dimension claim corrected
- Enhanced visuals: Okabe-Ito colourblind + viridis magma, theme_graph, 4160px — replaced standard graphs in place (no 'premium' naming, student-like scripts: task_b_network.R + network_visuals.R + network_graphs_final.R)
- Validation: sub-agent high-effort audit + independent recomputation (Pillow 17 PNGs 2720-4160px) — 12/12 PASS, documented in outputs/TASK_B_VALIDATION_REPORT.md:1
- GitHub: created hareeshkar/CIS6008_Civil_Aviation_BI_Project (public), 8 student commits, .gitignore covers *.rar, root samples, AGENTS.md, large raster, .venv, renv/library
- Updated AGENTS.md §10 with trustability factor + max-effort max-version requirement (user 2026-08-09)
