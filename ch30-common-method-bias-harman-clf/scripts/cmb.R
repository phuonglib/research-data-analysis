# =====================================================================
# Post 30. Common method variance / common method bias (CMB).
# 1. Harman's single-factor test: unrotated EFA on the 20 items
# 2. Harman as a CFA: one-factor model versus the five-factor model
# 3. Common latent factor (CLF): one extra factor loading on all 20 items,
#    equal loadings (label m), uncorrelated with the five factors
# 4. Robustness of the 7 paths when the CLF is added to the SEM
# 5. The same on the complete-case data (as AMOS uses them)
# 6. Likelihood profile over fixed CLF loadings
# Run: LANG=C.UTF-8 Rscript cmb.R
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]; xd <- na.omit(x)
fit_idx <- c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr")

# ---- 1. Harman: unrotated EFA (complete cases, listwise as in SPSS/PSPP)
R <- cor(xd)
ev <- eigen(R)$values
cat("Complete cases N =", nrow(xd), "\nEigenvalues (PCA):", round(ev[1:6], 3), "\n")
cat("% variance of factor 1 (PCA):", round(100 * ev[1] / 20, 2), "\n")
cat("Number of eigenvalues > 1:", sum(ev > 1), "\n")
cat("Cumulative % of 5 components:", round(100 * sum(ev[1:5]) / 20, 2), "\n")
# Principal axis factoring (PAF), 1 factor, iterating the communalities as SPSS does
h2 <- 1 - 1 / diag(solve(R))
for (k in 1:100) { Rr <- R; diag(Rr) <- h2; e <- eigen(Rr); l <- sqrt(e$values[1]) * e$vectors[, 1]; h2n <- l^2
  if (max(abs(h2n - h2)) < 1e-3) break; h2 <- h2n }
cat("% variance of 1 factor (PAF, after", k, "iterations):", round(100 * sum(l^2) / 20, 2), "\n")
write.csv(data.frame(component = 1:20, eigenvalue = ev, percent = 100 * ev / 20, cumulative = cumsum(100 * ev / 20)),
          file.path(here, "harman_eigenvalues.csv"), row.names = FALSE)

# ---- 2. CFA: 1 factor versus 5 factors (FIML, N = 267)
m5 <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
m1 <- paste("GENERAL =~", paste(items, collapse = " + "))
f5 <- cfa(m5, data = x, missing = "ml"); f1 <- cfa(m1, data = x, missing = "ml")
# ---- 3. CLF: equal loadings (label m), orthogonal to the 5 factors
mclf <- paste0(m5, '
  CLF =~ NA*CONF1 + ', paste0("m*", items, collapse = " + "), '
  CLF ~~ 1*CLF
  CLF ~~ 0*CONFIRM + 0*VALUE + 0*SATISF + 0*TRUST + 0*INTENT')
fc <- cfa(mclf, data = x, missing = "ml")
# CLF with free loadings (unconstrained version) for comparison
mclf2 <- paste0(m5, '
  CLF =~ ', paste(items, collapse = " + "), '
  CLF ~~ 0*CONFIRM + 0*VALUE + 0*SATISF + 0*TRUST + 0*INTENT')
fc2 <- suppressWarnings(cfa(mclf2, data = x, missing = "ml"))
cat("CLF with free loadings converged?", lavInspect(fc2, "converged"), "\n")
if (!lavInspect(fc2, "converged")) fc2 <- NULL
tab <- rbind("1 factor (Harman CFA)" = fitMeasures(f1, fit_idx), "5 factors (Post 22)" = fitMeasures(f5, fit_idx),
             "5 factors + CLF (equal loadings)" = fitMeasures(fc, fit_idx))
print(round(tab, 3))
print(anova(f1, f5)); print(anova(f5, fc))
write.csv(data.frame(model = rownames(tab), tab, row.names = NULL), file.path(here, "cmb_fit.csv"), row.names = FALSE)
# Number of parameters (to check the n(Parameters) columns of JASP's Model Fit table)
npar <- sapply(list(M1_five_factors = f5, M2_one_factor = f1, M3_CLF = fc), function(f)
  c(free = unname(fitMeasures(f, "npar")), rows_in_parameter_table = nrow(parTable(f)),
    fixed_rows = sum(parTable(f)$free == 0), log_likelihood = unname(fitMeasures(f, "logl")),
    AIC = unname(fitMeasures(f, "aic")), BIC = unname(fitMeasures(f, "bic"))))
cat("Parameters per model (JASP tab names):\n"); print(round(npar, 2))
# Standardized loadings with and without the CLF
s5 <- subset(standardizedSolution(f5), op == "=~")
sc <- subset(standardizedSolution(fc), op == "=~")
ld <- data.frame(item = s5$rhs, factor = s5$lhs, loading_without_CLF = s5$est.std,
                 loading_with_CLF = sc$est.std[sc$lhs != "CLF"], loading_on_CLF = sc$est.std[sc$lhs == "CLF"],
                 p_CLF = sc$pvalue[sc$lhs == "CLF"])
ld$difference <- ld$loading_without_CLF - ld$loading_with_CLF
ld$method_variance <- ld$loading_on_CLF^2
print(ld, digits = 3)
pm <- subset(parameterEstimates(fc), label == "m")[1, ]
cat("Unstandardized CLF loading m =", round(pm$est, 4), " SE =", round(pm$se, 4), " z =", round(pm$z, 3), " p =", signif(pm$pvalue, 3),
    " CI:", round(pm$ci.lower, 3), round(pm$ci.upper, 3), "\n")
cat("CLF variance fixed at 1. Mean % method variance:", round(100 * mean(ld$method_variance), 2),
    "%; range", round(100 * range(ld$method_variance), 2), "\n")
cat("Largest change in a loading:", round(max(abs(ld$difference)), 3), "\n")
if (!is.null(fc2)) { s2 <- subset(standardizedSolution(fc2), op == "=~" & lhs == "CLF"); cat("Free CLF, standardized loadings:", round(range(s2$est.std), 3), "; mean % variance:", round(100 * mean(s2$est.std^2), 2), "\n") }
write.csv(ld, file.path(here, "cmb_loadings.csv"), row.names = FALSE)
cat("Factor correlations without CLF:\n"); print(round(lavInspect(f5, "cor.lv"), 3))
cat("Factor correlations with CLF:\n"); print(round(lavInspect(fc, "cor.lv")[1:5, 1:5], 3))

# ---- 4. SEM with and without the CLF
structural <- '
  VALUE  ~ CONFIRM
  SATISF ~ CONFIRM + VALUE
  INTENT ~ CONFIRM + VALUE + SATISF + TRUST
  CONFIRM ~~ TRUST'
s0 <- sem(paste0(m5, structural), data = x, missing = "ml")
s1 <- sem(paste0(mclf, structural), data = x, missing = "ml")
p0 <- subset(parameterEstimates(s0, standardized = TRUE), op == "~")
p1 <- subset(parameterEstimates(s1, standardized = TRUE), op == "~")
pt <- data.frame(H = paste0("H", 1:7), path = paste(p0$lhs, "~", p0$rhs), beta_without = p0$std.all, p_without = p0$pvalue,
                 beta_CLF = p1$std.all, p_CLF = p1$pvalue)
pt$difference <- pt$beta_without - pt$beta_CLF
print(pt, digits = 3)
pv <- subset(parameterEstimates(s1), op == "~~" & lhs == rhs & lhs %in% c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT", "CLF"))
print(pv[, c("lhs", "est", "se", "pvalue")], digits = 3)
print(round(rbind(without = fitMeasures(s0, fit_idx), CLF = fitMeasures(s1, fit_idx)), 3))
cat("R2 without CLF:", round(lavInspect(s0, "r2")[c("VALUE", "SATISF", "INTENT")], 3), "\n")
cat("R2 with CLF:", round(lavInspect(s1, "r2")[c("VALUE", "SATISF", "INTENT")], 3), "\n")
cat("CLF loading m in the SEM:", round(subset(parameterEstimates(s1), label == "m")$est[1], 4), "\n")
write.csv(pt, file.path(here, "cmb_paths.csv"), row.names = FALSE)

# ---- 5. Complete-case data (as AMOS)
f5d <- cfa(m5, data = xd); f1d <- cfa(m1, data = xd); fcd <- cfa(mclf, data = xd)
bd <- rbind("1 factor" = fitMeasures(f1d, fit_idx), "5 factors" = fitMeasures(f5d, fit_idx), "5 factors + CLF" = fitMeasures(fcd, fit_idx))
cat("\nComplete cases N =", nrow(xd), "\n"); print(round(bd, 3)); print(anova(f1d, f5d)); print(anova(f5d, fcd))
scd <- subset(standardizedSolution(fcd), op == "=~" & lhs == "CLF"); s5d <- subset(standardizedSolution(f5d), op == "=~")
scd2 <- subset(standardizedSolution(fcd), op == "=~" & lhs != "CLF")
cat("CLF standardized loadings (complete):", round(range(scd$est.std), 3), " m =", round(subset(parameterEstimates(fcd), label == "m")$est[1], 4), " p =", signif(subset(parameterEstimates(fcd), label == "m")$pvalue[1], 3),
    "; largest change in a loading:", round(max(abs(s5d$est.std - scd2$est.std)), 3), "; mean % variance:", round(100 * mean(scd$est.std^2), 2), "\n")
write.csv(data.frame(model = rownames(bd), bd, row.names = NULL), file.path(here, "cmb_fit_complete.csv"), row.names = FALSE)
s0d <- sem(paste0(m5, structural), data = xd); s1d <- sem(paste0(mclf, structural), data = xd)
q0 <- subset(standardizedSolution(s0d), op == "~"); q1 <- subset(standardizedSolution(s1d), op == "~")
cat("Path coefficients (complete) without/with CLF:\n"); print(round(cbind(q0$est.std, q0$pvalue, q1$est.std, q1$pvalue), 3))

# ---- 6. Likelihood profile over the CLF loading (m fixed from 0 to 0.5): why the CLF is hard to identify
prof <- t(sapply(seq(0, 0.5, by = 0.025), function(mv) {
  mc <- paste0(m5, '\n CLF =~ ', paste0(mv, "*", items, collapse = " + "),
               '\n CLF ~~ 1*CLF\n CLF ~~ 0*CONFIRM + 0*VALUE + 0*SATISF + 0*TRUST + 0*INTENT')
  a <- cfa(mc, data = x, missing = "ml"); b <- sem(paste0(mc, structural), data = x, missing = "ml")
  sa <- subset(standardizedSolution(a), op == "=~" & lhs == "CLF")$est.std
  c(m = mv, mean_std_loading = mean(sa), chisq_CFA = unname(fitMeasures(a, "chisq")), chisq_SEM = unname(fitMeasures(b, "chisq")))
}))
print(round(prof, 3))
write.csv(as.data.frame(prof), file.path(here, "cmb_profile.csv"), row.names = FALSE)
