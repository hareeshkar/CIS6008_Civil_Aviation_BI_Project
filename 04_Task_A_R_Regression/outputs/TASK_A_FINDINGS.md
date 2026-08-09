# Task A Findings — Statistical Regression (n=200, Generated 2026-08-09)

> Source files: `03_Original_Datasets/Task_A/Air_Transport_Data.csv` → `working_data/Air_Transport_Data.csv` (copy-before-transform), `outputs/*.csv`, `outputs/multiple_regression_summary.txt:1`, `plots/*.png`. No imputed/fabricated numbers — all values below are read directly from generated outputs.

## 1. Data Quality & Descriptive Summary

- **Rows:** 200 observations, 7 numeric variables (`airport_traffic, avg_income, fuel_price, avg_ticket_fare, flight_frequency, route_distance, passenger_demand` — see `outputs/data_inspection.txt:1`). **Zero missing values** for all columns (`outputs/missing_values.csv:1`).
- **Dependent variable `passenger_demand`:** mean = 107,811.47, median = 109,586.05, SD = 53,856.39, range = –60,240.14 to 268,128.43, skew = –0.002 (symmetric), kurtosis = 0.24 (mesokurtic) (`outputs/descriptive_statistics.csv:1`). The negative minimum is non-physical (synthetic data artefact) — flagged for discussion, not removed.
- **Predictors:** `airport_traffic` mean 197,961 SD 46,550; `avg_income` 66,030 SD 11,844; `fuel_price` 0.887 SD 0.149; `avg_ticket_fare` 250.36 SD 40.78; `flight_frequency` 122.57 SD 19.12; `route_distance` 1,553 SD 412.
- **Methodology note for excellent band:** All continuous variables pass Shapiro-Wilk normality at α=0.05 (see §2) — parametric tests justified.

## 2. Normality (Shapiro-Wilk, n=200)

File: `outputs/normality_tests.csv:1`

| Variable | W | p | Normal? |
|---|---|---|---|
| airport_traffic | 0.9956 | 0.829 | Yes |
| avg_income | 0.9910 | 0.250 | Yes |
| fuel_price | 0.9964 | 0.922 | Yes |
| avg_ticket_fare | 0.9952 | 0.777 | Yes |
| flight_frequency | 0.9940 | 0.600 | Yes |
| route_distance | 0.9928 | 0.440 | Yes |
| passenger_demand | 0.9927 | 0.425 | Yes |

- **Interpretation:** Fail to reject H0 for every variable (all p >0.05). Residuals also normal (Shapiro W=0.9943, p=0.650 in `outputs/model_diagnostics.txt:1`). Q-Q plots (`plots/qq_*.png`, `qq_all_variables.png`) visually linear; histograms with density overlays confirm no severe skew.

## 3. Correlation with `passenger_demand` (Pearson, n=200)

File: `outputs/correlation_matrix.csv:1`, p-values `outputs/correlation_p_values.csv:1`, visual `plots/correlation_plot.png` & `correlation_heatmap.png`.

| Predictor | r (Pearson) | p | Strength |
|---|---|---|---|
| **airport_traffic** | **0.385** | **1.75×10⁻⁸** | Moderate positive — only statistically significant correlation with DV |
| fuel_price | 0.086 | 0.228 | Negligible, ns |
| flight_frequency | 0.052 | 0.463 | Negligible, ns |
| avg_income | 0.050 | 0.486 | Negligible, ns |
| route_distance | –0.041 | 0.563 | Negligible, ns |
| avg_ticket_fare | –0.030 | 0.669 | Negligible, ns |

- Between-IV correlations all |r| <0.18 (max 0.171 between `avg_ticket_fare`–`flight_frequency`, p=0.015; `avg_income`–`flight_frequency` –0.142 p=0.045). Scatterplots (`plots/passenger_demand_vs_*.png`) show diffuse clouds except `airport_traffic` which shows upward slope.

## 4. Simple Linear Regressions (DV ~ one IV)

File: `outputs/simple_regression_results.csv:1`, details `simple_regression_summaries.txt:1`. Sorted by R²:

| IV | Slope (b) | 95% CI | R² | Adj R² | p (slope) | Significant? |
|---|---|---|---|---|---|---|
| **airport_traffic** | 0.446 (SE 0.076) | 0.296–0.596 | **0.1485** | **0.1442** | 1.75×10⁻⁸ | *** Yes |
| fuel_price | 30,945 (SE 25,574) | –19,488–81,379 | 0.0073 | 0.0023 | 0.228 | No |
| flight_frequency | 147.06 (SE 199.9) | –247–541 | 0.0027 | –0.0023 | 0.463 | No |
| avg_income | 0.225 (SE 0.323) | –0.41–0.86 | 0.0025 | –0.0026 | 0.486 | No |
| route_distance | –5.38 (SE 9.28) | –23.68–12.92 | 0.0017 | –0.0033 | 0.563 | No |
| avg_ticket_fare | –40.14 (SE 93.80) | –225–145 | 0.0009 | –0.0041 | 0.669 | No |

- **Answer — which correlates most / highest R²?** `airport_traffic` is the only predictor with meaningful bivariate association: each +1 passenger handled is associated with +0.45 passengers of demand on the modelled route (mechanical correlation), explaining 14.9% of variance. All other IVs explain <1% individually and are non-significant.

## 5. Multiple Linear Regression (All 6 IVs)

Files: `outputs/multiple_regression_summary.txt:1`, `multiple_regression_coefficients.csv:1`, `model_comparison.csv:1`.

**Formula:** `passenger_demand ~ airport_traffic + avg_income + fuel_price + avg_ticket_fare + flight_frequency + route_distance`

```
Coefficients (n=200, df=193):
                        Estimate  Std.Error  t    p        95% CI
(Intercept)             -37,745    47,291  -0.798 0.426   –131,019 to 55,529
airport_traffic           0.476     0.077   6.167 4.0e-09***  0.324 to 0.628
avg_income                0.081     0.302   0.267 0.790     –0.515 to 0.676
fuel_price               53,538    23,999   2.231 0.027*      6,204 to 100,872
avg_ticket_fare            –112      88.5  –1.262 0.208       –286 to 62.9
flight_frequency            221       189    1.170 0.244       –152 to 594
route_distance             –0.38      8.63  –0.044 0.965       –17.4 to 16.6
---
Residual SE = 49,555; Multiple R² = 0.1789, Adj R² = 0.1534
F(6,193) = 7.008, p = 9.27×10⁻⁷; AIC = 4900.78, BIC = 4927.17, logLik = –2442.39
```

- **Model vs simple:** `model_comparison.csv` ranks multiple (Adj R² 0.153) slightly above best simple (Adj R² 0.144) — adding five variables gains only ~0.9 pp of adjusted variance. Simple `airport_traffic` alone (AIC 4898) actually fits slightly better by AIC than the 6-variable model (AIC 4900.8) — suggests parsimony favours the single-predictor model.
- **Which variables remain important when all are together?** Only two survive:
  1. `airport_traffic` — strong, highly significant (p 4×10⁻⁹, CI does not cross zero).
  2. `fuel_price` — emerges as significant (p=0.027) with large positive coefficient (53,538) and CI 6,204–100,872. This is **counter-intuitive** (higher fuel → higher demand) and was non-significant in bivariate; it suggests a suppression / confounding artefact in the synthetic dataset rather than a causal effect — must be flagged, not presented as policy that raising fuel boosts demand.
  - `avg_income` (p=0.79), `avg_ticket_fare` (p=0.208), `flight_frequency` (p=0.244), `route_distance` (p=0.965) all non-significant (CIs cross zero).

## 6. Are There Obvious Model Problems?

File: `outputs/model_diagnostics.txt:1`, `vif_values.csv:1`, plots `diagnostics_residuals_vs_fitted.png`, `qq_residuals.png`, `scale_location.png`, `top_influential_points.csv:1`.

- **Multicollinearity:** No. All VIF = 1.03–1.06 (well below 5). Tolerance >0.94.
- **Residual normality:** Pass. Shapiro W=0.9943 p=0.650; Q-Q plot of standardized residuals linear.
- **Homoscedasticity:** Pass. Breusch-Pagan BP=4.84 df=6 p=0.564 → fail to reject equal variance; Scale-Location plot flat.
- **Autocorrelation:** Pass. Durbin-Watson DW=2.07 p=0.697 → independent residuals.
- **Influence:** Moderate — max Cook's D=0.062 (row 147, residual –135,506) below 0.5/1 thresholds; max hat=0.10. Fifteen points have |std resid| >1.7 but none distort the fit severely (`top_influential_points.csv`). Check `plots/residuals_vs_leverage.png`.
- **Real problem — low explanatory power:** R²=0.18 / Adj R²=0.15 means **~82-85% of passenger_demand variance is unexplained** by these 6 variables. Residual range –135k to +122k is large relative to mean 108k, and residual SE 49,555 is ~46% of mean demand. The model is statistically significant overall (F p<10⁻⁶) but practically weak for forecasting — major omitted variables (e.g., seasonality, GDP, tourism, competition, airfare elasticity lags, events) are missing. Also the DV’s negative minimum violates domain logic — synthetic generation artefact.
- **Interpretive hazard:** Positive `fuel_price` coefficient contradicts aviation economics — do not interpret causally without external validation.

## 7. Business Implications for Sri Lankan Civil Aviation (Evidence-Based)

1. **Airport traffic is the only robust short-run predictor.** Using the multiple model, `+1,000 airport passengers handled` → `+476 passengers` of route demand (95% CI 324–628), ceteris paribus. The simple model gives +446 per 1,000. For BIA capacity planning, this supports using airport throughput as a demand proxy for staffing, gate allocation, and slot negotiations — but not as sole forecaster (R² <0.15).
2. **Income, ticket fare, frequency, and route distance do not show statistically significant marginal effects in this dataset** (all p>0.2). This does not prove they are irrelevant in reality — it indicates this 200-row synthetic sample lacks power or structure to detect them. The Ministry should **not** conclude that fare or income are unimportant; rather, this dataset is insufficient.
3. **Fuel price requires careful handling.** The positive multivariate coefficient would naïvely suggest tolerating higher fuel, but the bivariate null and economic theory argue the opposite. Recommend: treat as data artefact, test with lagged/out-of-sample data and include hedging cost scenarios separately, not via this regression.
4. **Forecasting recommendation:** Do not deploy this 6-variable OLS for BIA demand forecasting as-is (Adj R² 0.15). Feasible BI path: (a) enrich data (ICAO/IATA traffic, GDP, tourist arrivals, exchange rates, seasonality dummies, competitor capacity, event flags); (b) compare models (stepwise, regularised `glmnet`, time-series `forecast::auto.arima`); (c) validate out-of-sample (train/test split, RMSE/MAE); (d) report prediction intervals, not point forecasts.
5. **Resource optimisation now:** Use `airport_traffic` correlation for near-term operational scaling (ground handling, fuel contracts) while investing in richer data collection (PostGIS/ADS-B, passenger surveys) to enable genuine predictive BI — directly supporting foreign-exchange optimisation and sustainable growth goals of the Ministry.

## 8. Files for Appendix / Presentation

Cite these exact paths in report/presentation appendices to reach “Excellent” evidence standard:

- Descriptive: `outputs/descriptive_statistics.csv` (and `_psych.csv`), `tables/descriptive_statistics.csv`
- Normality: `outputs/normality_tests.csv`, `plots/qq_all_variables.png` + `hist_*.png`
- Correlation: `outputs/correlation_matrix.csv`, `correlation_p_values.csv`, `plots/correlation_plot.png`, `correlation_heatmap.png`
- Simple: `outputs/simple_regression_results.csv`, `simple_regression_summaries.txt`
- Multiple: `outputs/multiple_regression_summary.txt`, `multiple_regression_coefficients.csv`, `model_comparison.csv`
- Diagnostics: `outputs/model_diagnostics.txt`, `vif_values.csv`, `plots/diagnostics_residuals_vs_fitted.png`, `residuals_vs_fitted.png`, `scale_location.png`, `qq_residuals.png`, `top_influential_points.csv`
- Scatter: `plots/passenger_demand_vs_airport_traffic.png` (and 5 others)
- This summary: `outputs/TASK_A_FINDINGS.md` (this file)

---
*Generated from Rscript `04_Task_A_R_Regression/scripts/task_a_regression.R` run 2026-08-09, R 4.5.2, packages tidyverse 2.0.0 car 3.1-5 lmtest 0.9.40 corrplot 0.95 psych 2.6.5, n=200, seed not applicable (deterministic CSV). All p-values two-sided.*
