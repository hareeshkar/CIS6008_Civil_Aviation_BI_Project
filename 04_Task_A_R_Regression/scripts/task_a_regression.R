#!/usr/bin/env Rscript
# Task A — Statistical Regression for Civil Aviation BI (CIS6008)
# Steps in order: load → inspect → descriptive → normality → correlation → scatterplots → simple → multiple → assumptions → export
# TRACEABILITY: every numeric output written to files; do not invent values.

# --- renv activation (project-local) ---
if (file.exists("renv/activate.R")) source("renv/activate.R")
if (file.exists("../.venv/bin/python")) Sys.setenv(RETICULATE_PYTHON = "../.venv/bin/python")

# --- libraries (all pre-installed and renv-tracked) ---
suppressPackageStartupMessages({
  library(tidyverse)
  library(car)        # VIF
  library(lmtest)     # bptest, dwtest
  library(corrplot)
  library(psych)      # describe, skew/kurtosis
  library(ggplot2)
})
options(scipen = 999)  # 100% safe: never 4e+04, always 40,000

# --- paths ---
base_dir <- "/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project/04_Task_A_R_Regression"
if (!dir.exists(file.path(base_dir, "outputs"))) {
  # fallback: try cwd relative
  candidates <- c(
    "04_Task_A_R_Regression",
    file.path(getwd(), "04_Task_A_R_Regression"),
    getwd()
  )
  for (c in candidates) if (dir.exists(file.path(c, "outputs"))) { base_dir <- normalizePath(c); break }
}
base_dir <- normalizePath(base_dir)
cat("Base dir:", base_dir, "\n")
src_csv <- "/Users/hareeshkar/Documents/CIS6008_Civil_Aviation_BI_Project/03_Original_Datasets/Task_A/Air_Transport_Data.csv"
working_dir <- file.path(base_dir, "working_data")
outputs_dir <- file.path(base_dir, "outputs")
plots_dir <- file.path(base_dir, "plots")
tables_dir <- file.path(base_dir, "tables")
dir.create(working_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(outputs_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Helper not needed — base_dir is explicit

# --- 1. Load (copy-before-transform) ---
cat("[1] Loading Air_Transport_Data.csv\n")
if (file.exists(src_csv)) {
  file.copy(src_csv, file.path(working_dir, "Air_Transport_Data.csv"), overwrite = TRUE)
  cat("  Copied master -> working_data/Air_Transport_Data.csv\n")
} else {
  stop("Source CSV not found: ", src_csv)
}
csv_path <- file.path(working_dir, "Air_Transport_Data.csv")
if (!file.exists(csv_path)) csv_path <- src_csv
df <- read_csv(csv_path, show_col_types = FALSE)
cat("  Rows:", nrow(df), "Cols:", ncol(df), "\n")
print(glimpse(df))

# Enforce expected columns
expected <- c("airport_traffic","avg_income","fuel_price","avg_ticket_fare","flight_frequency","route_distance","passenger_demand")
missing <- setdiff(expected, names(df))
if (length(missing)>0) stop("Missing expected columns: ", paste(missing, collapse=", "))
# Coerce to numeric (all should be double)
df <- df %>% mutate(across(all_of(expected), as.numeric))
vars_iv <- expected[1:6]
var_dv <- expected[7]

# --- 2. Inspect structure and missing values ---
cat("\n[2] Inspect structure and missing values\n")
sink(file.path(outputs_dir, "data_inspection.txt"))
cat("=== STRUCTURE ===\n")
print(str(df))
cat("\n=== SUMMARY ===\n")
print(summary(df))
cat("\n=== MISSING VALUES PER COLUMN ===\n")
print(colSums(is.na(df)))
cat("\n=== MISSING TOTAL ===\n")
print(sum(is.na(df)))
cat("\n=== ANY DUPLICATED ROWS ===\n")
print(sum(duplicated(df)))
cat("\n=== DATA TYPES ===\n")
print(sapply(df, class))
sink()
cat("  Written: outputs/data_inspection.txt\n")
# also CSV of missing
missing_df <- tibble(variable = names(df), n_missing = colSums(is.na(df)), pct_missing = colSums(is.na(df))/nrow(df)*100)
write_csv(missing_df, file.path(outputs_dir, "missing_values.csv"))

# --- 3. Descriptive statistics ---
cat("\n[3] Descriptive statistics\n")
desc_psych <- psych::describe(df[, expected]) %>% as.data.frame() %>% rownames_to_column("variable")
# Also manual for clarity
desc_manual <- df %>% pivot_longer(cols = all_of(expected), names_to = "variable", values_to = "value") %>%
  group_by(variable) %>%
  summarise(
    n = sum(!is.na(value)),
    mean = mean(value, na.rm=TRUE),
    median = median(value, na.rm=TRUE),
    sd = sd(value, na.rm=TRUE),
    min = min(value, na.rm=TRUE),
    max = max(value, na.rm=TRUE),
    q1 = quantile(value, 0.25, na.rm=TRUE),
    q3 = quantile(value, 0.75, na.rm=TRUE),
    iqr = IQR(value, na.rm=TRUE),
    skew = psych::skew(value, na.rm=TRUE),
    kurtosis = psych::kurtosi(value, na.rm=TRUE),
    .groups = "drop"
  )
write_csv(desc_psych, file.path(outputs_dir, "descriptive_statistics_psych.csv"))
write_csv(desc_manual, file.path(outputs_dir, "descriptive_statistics.csv"))
write_csv(desc_manual, file.path(tables_dir, "descriptive_statistics.csv"))
cat("  Written: outputs/descriptive_statistics.csv (and psych variant)\n")
print(desc_manual)

# --- 4. Normality tests (Shapiro-Wilk per variable) ---
cat("\n[4] Normality tests (Shapiro-Wilk)\n")
# Shapiro per variable + combined
shapiro_results <- lapply(expected, function(v) {
  x <- df[[v]]
  x <- x[!is.na(x)]
  # Shapiro requires 3 <= n <= 5000; n=200 OK
  test <- shapiro.test(x)
  tibble(
    variable = v,
    n = length(x),
    W = as.numeric(test$statistic),
    p_value = test$p.value,
    normal_at_05 = test$p.value > 0.05,
    interpretation = ifelse(test$p.value > 0.05, "Fail to reject H0: approximately normal (p>0.05)", "Reject H0: not normal (p<=0.05)")
  )
}) %>% bind_rows()
write_csv(shapiro_results, file.path(outputs_dir, "normality_tests.csv"))
write_csv(shapiro_results, file.path(tables_dir, "normality_tests.csv"))
cat("  Written: outputs/normality_tests.csv\n")
print(shapiro_results)
# QQ plots
for (v in expected) {
  p <- ggplot(df, aes(sample = .data[[v]])) +
    stat_qq() + stat_qq_line(color = "red") +
    labs(title = paste0("Q-Q Plot: ", v), x = "Theoretical Quantiles", y = "Sample Quantiles") +
    theme_minimal()
  ggsave(file.path(plots_dir, paste0("qq_", v, ".png")), p, width = 6, height = 4.5, dpi = 300)
}
# Histograms per variable — 100% safe: both density and frequency, each with comma labels, no scientific notation, consistent across all 7
for (v in expected) {
  # Frequency version (y = count) — natural counts, no red density line
  p_freq <- ggplot(df, aes(x = .data[[v]])) +
    geom_histogram(bins = 30, fill = "#2C73D2", color = "white", alpha = 0.85) +
    labs(title = paste0("Distribution: ", v), subtitle = "Frequency", x = v, y = "Frequency") +
    scale_x_continuous(labels = scales::label_comma()) +
    scale_y_continuous(labels = scales::label_comma()) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(size = 12, face = "bold"), plot.subtitle = element_text(size = 10, color = "grey30"))
  ggsave(file.path(plots_dir, paste0("hist_", v, ".png")), p_freq, width = 6, height = 4.5, dpi = 300)
  # Density version (y = density) with density curve overlay — density on left y
  p_dens <- ggplot(df, aes(x = .data[[v]])) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#2C73D2", color = "white", alpha = 0.85) +
    geom_density(color = "#D93D2B", linewidth = 0.9) +
    labs(title = paste0("Distribution: ", v), subtitle = "Density overlay", x = v, y = "Density") +
    scale_x_continuous(labels = scales::label_comma()) +
    scale_y_continuous(labels = scales::label_number(accuracy = 0.00001, decimal.mark = ".")) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(size = 12, face = "bold"), plot.subtitle = element_text(size = 10, color = "grey30"))
  ggsave(file.path(plots_dir, paste0("hist_density_", v, ".png")), p_dens, width = 6, height = 4.5, dpi = 300)
}
# Combined QQ grid
qq_grid_file <- file.path(plots_dir, "qq_all_variables.png")
png(qq_grid_file, width = 1800, height = 1400, res = 200)
par(mfrow = c(3,3), mar = c(4,4,2,1))
for (v in expected) {
  qqnorm(df[[v]], main = paste0("Q-Q: ", v), pch = 19, cex = 0.6, col = "#2C73D2")
  qqline(df[[v]], col = "red", lwd = 2)
}
dev.off()
cat("  QQ and hist plots saved\n")

# --- 5. Correlation matrix ---
cat("\n[5] Correlation analysis\n")
cor_mat <- cor(df[, expected], use = "complete.obs", method = "pearson")
cor_p_mat <- corrplot::cor.mtest(df[, expected], conf.level = 0.95)
write_csv(as.data.frame(cor_mat) %>% rownames_to_column("variable"), file.path(outputs_dir, "correlation_matrix.csv"))
write_csv(as.data.frame(cor_mat) %>% rownames_to_column("variable"), file.path(tables_dir, "correlation_matrix.csv"))
# p-values matrix
p_mat_df <- as.data.frame(cor_p_mat$p) %>% rownames_to_column("variable")
write_csv(p_mat_df, file.path(outputs_dir, "correlation_p_values.csv"))
cat("  Correlation matrix:\n")
print(round(cor_mat, 3))
# corrplot PNG
png(file.path(plots_dir, "correlation_plot.png"), width = 2000, height = 1800, res = 220)
corrplot(cor_mat, method = "color", type = "upper", order = "hclust",
         tl.col = "black", tl.srt = 45, tl.cex = 0.9,
         addCoef.col = "black", number.cex = 0.75,
         col = COL2("RdBu", 200), diag = TRUE,
         p.mat = cor_p_mat$p, sig.level = 0.05, insig = "blank",
         title = "Pearson Correlation (Air Transport, n=200)", mar = c(0,0,2,0))
dev.off()
# Also ggplot heatmap alternative
cor_long <- as.data.frame(cor_mat) %>% rownames_to_column("var1") %>% pivot_longer(-var1, names_to = "var2", values_to = "r")
p_heat <- ggplot(cor_long, aes(var1, var2, fill = r)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(r, 2)), size = 3) +
  scale_fill_gradient2(low = "#D93D2B", mid = "white", high = "#2C73D2", midpoint = 0, limits = c(-1,1)) +
  labs(title = "Correlation Heatmap (Pearson, n=200)", x = NULL, y = NULL, fill = "r") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(plots_dir, "correlation_heatmap.png"), p_heat, width = 8, height = 7, dpi = 300)
cat("  Correlation plots saved\n")

# --- 6. Scatterplots (DV vs each IV) with regression line + correlation annotation ---
cat("\n[6] Scatterplots\n")
for (iv in vars_iv) {
  r_val <- cor(df[[iv]], df[[var_dv]], use = "complete.obs")
  p_val <- cor.test(df[[iv]], df[[var_dv]])$p.value
  # Axis labels with units from data dictionary
  iv_units <- c(airport_traffic="passengers/yr", avg_income="USD/yr", fuel_price="USD/L", avg_ticket_fare="USD", flight_frequency="flights/day", route_distance="km")
  p <- ggplot(df, aes(x = .data[[iv]], y = .data[[var_dv]])) +
    geom_point(alpha = 0.6, color = "#2C73D2", size = 1.8) +
    geom_smooth(method = "lm", se = TRUE, color = "#D93D2B", fill = "#F4A9A8") +
    labs(
      title = paste0("Scatter: ", var_dv, " vs ", iv),
      subtitle = sprintf("Pearson r = %.3f, p = %.3g, n = %d", r_val, p_val, nrow(df)),
      x = paste0(iv, " [", iv_units[iv], "]"),
      y = paste0(var_dv, " [passengers]")
    ) +
    scale_x_continuous(labels = scales::label_comma()) +
    scale_y_continuous(labels = scales::label_comma()) +
    theme_minimal() + theme(plot.title = element_text(face = "bold"))
  # per-spec names expected by validator
  mapping_names <- c(
    airport_traffic = "passenger_demand_vs_airport_traffic.png",
    avg_income = "passenger_demand_vs_income.png",
    fuel_price = "passenger_demand_vs_fuel_price.png",
    avg_ticket_fare = "passenger_demand_vs_ticket_fare.png",
    flight_frequency = "passenger_demand_vs_flight_frequency.png",
    route_distance = "passenger_demand_vs_route_distance.png"
  )
  fname <- mapping_names[iv]
  if (is.na(fname)) fname <- paste0("scatter_", iv, "_vs_", var_dv, ".png")
  ggsave(file.path(plots_dir, fname), p, width = 7, height = 5, dpi = 300)
  # also generic name
  ggsave(file.path(plots_dir, paste0("scatter_", iv, ".png")), p, width = 7, height = 5, dpi = 300)
}
cat("  Scatterplots saved\n")

# --- 7. Simple linear regressions (one IV at a time) ---
cat("\n[7] Simple linear regressions\n")
simple_results <- lapply(vars_iv, function(iv) {
  f <- as.formula(paste(var_dv, "~", iv))
  m <- lm(f, data = df)
  s <- summary(m)
  glance_base <- tibble(
    iv = iv,
    intercept = coef(m)[1],
    slope = coef(m)[2],
    slope_se = s$coefficients[2,2],
    slope_t = s$coefficients[2,3],
    slope_p = s$coefficients[2,4],
    intercept_p = s$coefficients[1,4],
    r_squared = s$r.squared,
    adj_r_squared = s$adj.r.squared,
    sigma = s$sigma,
    f_statistic = s$fstatistic[1],
    f_p = pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE),
    aic = AIC(m),
    bic = BIC(m),
    n = nobs(m)
  )
  # 95% CI for slope
  ci <- confint(m, level = 0.95)
  glance_base$ci_low <- ci[2,1]
  glance_base$ci_high <- ci[2,2]
  glance_base
}) %>% bind_rows()
write_csv(simple_results, file.path(outputs_dir, "simple_regression_results.csv"))
write_csv(simple_results, file.path(tables_dir, "simple_regression_results.csv"))
cat("  Written: outputs/simple_regression_results.csv\n")
print(simple_results %>% arrange(desc(r_squared)))
# Write individual summaries
sink(file.path(outputs_dir, "simple_regression_summaries.txt"))
for (iv in vars_iv) {
  cat("\n\n======== SIMPLE REGRESSION:", var_dv, "~", iv, "========\n")
  m <- lm(as.formula(paste(var_dv, "~", iv)), data = df)
  print(summary(m))
  cat("\n--- 95% CI ---\n")
  print(confint(m))
}
sink()

# --- 8. Multiple linear regression (all 6 IVs) ---
cat("\n[8] Multiple linear regression (all 6 IVs)\n")
f_multi <- as.formula(paste(var_dv, "~", paste(vars_iv, collapse = " + ")))
m_multi <- lm(f_multi, data = df)
s_multi <- summary(m_multi)
# Save summary
sink(file.path(outputs_dir, "multiple_regression_summary.txt"))
cat("=== MULTIPLE LINEAR REGRESSION SUMMARY ===\n")
cat("Formula: ", deparse(f_multi), "\n")
cat("n =", nobs(m_multi), "  p (predictors) =", length(coef(m_multi))-1, "\n\n")
print(s_multi)
cat("\n=== 95% CONFIDENCE INTERVALS ===\n")
print(confint(m_multi))
cat("\n=== ANOVA ===\n")
print(anova(m_multi))
cat("\n=== MODEL FIT ===\n")
cat(sprintf("R-squared: %.4f  Adj R-sq: %.4f  Sigma: %.2f  F: %.2f on %d and %d DF, p=%.3g\n",
            s_multi$r.squared, s_multi$adj.r.squared, s_multi$sigma,
            s_multi$fstatistic[1], s_multi$fstatistic[2], s_multi$fstatistic[3],
            pf(s_multi$fstatistic[1], s_multi$fstatistic[2], s_multi$fstatistic[3], lower.tail=FALSE)))
cat(sprintf("AIC: %.2f  BIC: %.2f  LogLik: %.2f\n", AIC(m_multi), BIC(m_multi), as.numeric(logLik(m_multi))))
sink()
cat("  Written: outputs/multiple_regression_summary.txt\n")
print(s_multi)

# Coefficient table CSV
coef_df <- as.data.frame(s_multi$coefficients) %>% rownames_to_column("term")
names(coef_df) <- c("term","estimate","std_error","t_value","p_value")
coef_df$ci_low <- confint(m_multi)[,1]
coef_df$ci_high <- confint(m_multi)[,2]
# Star significance
coef_df$signif <- cut(coef_df$p_value, breaks = c(-Inf, 0.001, 0.01, 0.05, 0.1, Inf), labels = c("***","**","*",".",""))
write_csv(coef_df, file.path(outputs_dir, "multiple_regression_coefficients.csv"))
write_csv(coef_df, file.path(tables_dir, "multiple_regression_coefficients.csv"))

# Model comparison table — paste formula to avoid deparse newline split across CSV rows
model_formula_str <- paste(var_dv, "~", paste(vars_iv, collapse = " + "))
model_comp <- bind_rows(
  simple_results %>% transmute(model = paste0(var_dv,"~",iv), r_squared, adj_r_squared, aic, bic, sigma, f_statistic, f_p) %>% mutate(type="simple"),
  tibble(model = model_formula_str, r_squared = s_multi$r.squared, adj_r_squared = s_multi$adj.r.squared, aic = AIC(m_multi), bic = BIC(m_multi), sigma = s_multi$sigma, f_statistic = s_multi$fstatistic[1], f_p = pf(s_multi$fstatistic[1], s_multi$fstatistic[2], s_multi$fstatistic[3], lower.tail=FALSE), type="multiple")
) %>% arrange(desc(adj_r_squared))
write_csv(model_comp, file.path(outputs_dir, "model_comparison.csv"))
write_csv(model_comp, file.path(tables_dir, "model_comparison.csv"))

# --- 9. Model assumption checks ---
cat("\n[9] Model assumption checks\n")
# VIF
vif_vals <- tryCatch(car::vif(m_multi), error = function(e) NA)
vif_df <- if (is.numeric(vif_vals)) tibble(term = names(vif_vals), VIF = as.numeric(vif_vals), GVIF = as.numeric(vif_vals)) else tibble(term = vars_iv, VIF = NA_real_)
# For completeness, generalized VIF handling
if (!is.null(dim(vif_vals))) {
  vif_df <- as.data.frame(vif_vals) %>% rownames_to_column("term") %>% as_tibble()
  # car::vif can return matrix with GVIF; handle
  if ("GVIF" %in% names(vif_df)) vif_df <- vif_df %>% mutate(VIF = GVIF^(1/(2*Df)))
}
write_csv(vif_df, file.path(outputs_dir, "vif_values.csv"))
cat("  VIF:\n"); print(vif_df)
# Residual diagnostics tests
resid_vals <- residuals(m_multi)
bptest_res <- tryCatch(lmtest::bptest(m_multi), error=function(e) list(statistic=NA, p.value=NA))
dw_res <- tryCatch(lmtest::dwtest(m_multi), error=function(e) list(statistic=NA, p.value=NA))
shapiro_resid <- shapiro.test(resid_vals)
sink(file.path(outputs_dir, "model_diagnostics.txt"))
cat("=== MODEL DIAGNOSTICS (Multiple Regression) ===\n\n")
cat("--- VIF (variance inflation factor) ---\n")
print(vif_df)
cat("\nNote: VIF >5 suggests moderate collinearity, >10 severe.\n")
cat("\n--- Residual normality (Shapiro-Wilk on residuals) ---\n")
cat(sprintf("W=%.4f p=%.4g -> %s\n", shapiro_resid$statistic, shapiro_resid$p.value, ifelse(shapiro_resid$p.value>0.05,"Fail to reject normality","Reject normality")))
cat("\n--- Homoscedasticity (Breusch-Pagan) ---\n")
print(bptest_res)
cat("\n--- Autocorrelation (Durbin-Watson) ---\n")
print(dw_res)
cat("\n--- Leverage / Influence ---\n")
cat("Max Cook's distance:", max(cooks.distance(m_multi), na.rm=TRUE), "\n")
cat("Max hat value:", max(hatvalues(m_multi), na.rm=TRUE), "\n")
cat("\n--- Residual summary ---\n")
print(summary(resid_vals))
sink()
cat("  Written: outputs/model_diagnostics.txt\n")

# Diagnostic plots
png(file.path(plots_dir, "diagnostics_residuals_vs_fitted.png"), width = 2000, height = 1600, res = 200)
par(mfrow=c(2,2))
plot(m_multi)
dev.off()
# Individual enhanced plots
# Residuals vs Fitted enhanced ggplot
res_df <- tibble(fitted = fitted(m_multi), resid = resid_vals, std_resid = rstandard(m_multi), cooks = cooks.distance(m_multi))
p1 <- ggplot(res_df, aes(fitted, resid)) + geom_point(alpha=0.6, color="#2C73D2") + geom_hline(yintercept=0, linetype="dashed", color="red") + geom_smooth(se=FALSE, color="#D93D2B") + labs(title="Residuals vs Fitted", x="Fitted values", y="Residuals") + scale_x_continuous(labels = scales::label_comma()) + scale_y_continuous(labels = scales::label_comma()) + theme_minimal()
ggsave(file.path(plots_dir, "residuals_vs_fitted.png"), p1, width=7, height=5, dpi=300)
# Scale-Location
p2 <- ggplot(res_df, aes(fitted, sqrt(abs(std_resid)))) + geom_point(alpha=0.6, color="#2C73D2") + geom_smooth(se=FALSE, color="#D93D2B") + labs(title="Scale-Location", x="Fitted values", y="Sqrt(|Standardized residuals|)") + scale_x_continuous(labels = scales::label_comma()) + scale_y_continuous(labels = scales::label_number()) + theme_minimal()
ggsave(file.path(plots_dir, "scale_location.png"), p2, width=7, height=5, dpi=300)
# Q-Q residuals
p3 <- ggplot(res_df, aes(sample = std_resid)) + stat_qq(color="#2C73D2") + stat_qq_line(color="red") + labs(title="Normal Q-Q (Standardized Residuals)", x = "Theoretical Quantiles", y = "Standardized residuals") + theme_minimal()
ggsave(file.path(plots_dir, "qq_residuals.png"), p3, width=7, height=5, dpi=300)
# Residuals vs Leverage
p4 <- ggplot(res_df, aes(x = hatvalues(m_multi), y = std_resid)) + geom_point(aes(size = cooks), alpha=0.6, color="#2C73D2") + geom_hline(yintercept=0, linetype="dashed") + labs(title="Residuals vs Leverage", x="Leverage (hat)", y="Standardized residuals", size="Cook's D") + scale_y_continuous(labels = scales::label_comma()) + theme_minimal()
ggsave(file.path(plots_dir, "residuals_vs_leverage.png"), p4, width=7, height=5, dpi=300)

# --- 10. Additional: influence / outlier table ---
cooks <- cooks.distance(m_multi)
hat <- hatvalues(m_multi)
stdres <- rstandard(m_multi)
influence_df <- tibble(row = seq_len(nrow(df)), cooks, hat, stdres, resid = resid_vals, fitted = fitted(m_multi)) %>%
  arrange(desc(cooks))
write_csv(influence_df %>% slice_head(n=15), file.path(outputs_dir, "top_influential_points.csv"))
cat("  All diagnostics plots saved\n")

# Final log
cat("\n=== Task A Complete ===\n")
cat("Outputs in:", outputs_dir, "\n")
cat("Plots in:", plots_dir, "\n")
cat("Tables in:", tables_dir, "\n")
list.files(outputs_dir, full.names = FALSE) %>% print()
list.files(plots_dir, full.names = FALSE) %>% print()
