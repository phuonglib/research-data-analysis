# =====================================================================
# Post 23. Model fit indices: comparing three measurement models
#   M5: 5 factors (the theoretical model)
#   M4: 4 factors, VALUE and SATISF merged into one factor (VALSAT)
#   M1: 1 factor (all items measure the same concept, GENERAL)
# Run: LANG=C.UTF-8 Rscript compare_model_fit.R
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R",
           paste0("RI", 1:4))
x <- d[, items]; xc <- na.omit(x)

m5 <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
m4 <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALSAT  =~ PV1 + PV2 + PV3 + PV4 + SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
m1 <- paste("GENERAL =~", paste(items, collapse = " + "))

measures <- c("npar", "chisq", "df", "pvalue", "cfi", "tli", "nfi", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
              "rmsea.pvalue", "srmr", "gfi_lisrel", "agfi_lisrel", "aic", "bic")
# lavaan 0.7 reports a population GFI (with a confidence interval) as "gfi"; the classic GFI and AGFI
# printed by AMOS (and JASP) are "gfi_lisrel" and "agfi_lisrel"
fit_table <- function(dat, missing) {
  fits <- list(M5 = cfa(m5, dat, missing = missing), M4 = cfa(m4, dat, missing = missing),
               M1 = cfa(m1, dat, missing = missing))
  t <- t(sapply(fits, function(f) fitMeasures(f, measures)))
  colnames(t)[colnames(t) == "gfi_lisrel"] <- "gfi"; colnames(t)[colnames(t) == "agfi_lisrel"] <- "agfi"
  t <- cbind(t, cmin_df = t[, "chisq"] / t[, "df"])
  list(fits = fits, t = t)
}
fiml <- fit_table(x, "ml")
comp <- fit_table(xc, "listwise")
cat("=== FIML, N = 267 ===\n"); print(round(fiml$t, 3))
cat("=== Complete cases, N = 254 (as AMOS when it reports GFI, AGFI) ===\n"); print(round(comp$t, 3))
write.csv(round(fiml$t, 4), file.path(here, "model_fit_fiml.csv"))
write.csv(round(comp$t, 4), file.path(here, "model_fit_complete.csv"))

cat("=== Chi-square difference tests (FIML) ===\n")
print(anova(fiml$fits$M5, fiml$fits$M4))
print(anova(fiml$fits$M4, fiml$fits$M1))
cat("=== Chi-square difference tests (complete cases) ===\n")
print(anova(comp$fits$M5, comp$fits$M4))
print(anova(comp$fits$M4, comp$fits$M1))
cat("VALUE-SATISF correlation in M5:",
    round(subset(standardizedSolution(fiml$fits$M5), lhs == "VALUE" & rhs == "SATISF")$est.std, 3), "\n")
print(subset(standardizedSolution(fiml$fits$M5), lhs == "VALUE" & rhs == "SATISF"))

# Chi-square depends on sample size: same misfit, sample size doubled and quadrupled
cat("=== Chi-square of M4 with the sample size doubled and quadrupled (same covariance matrix) ===\n")
S <- cov(xc)
for (n in c(254, 508, 1016)) {
  f <- cfa(m4, sample.cov = S, sample.nobs = n)
  fm <- fitMeasures(f, c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr"))
  cat(sprintf("N = %4d: chi2 = %7.2f, p = %.4f, CFI = %.3f, RMSEA = %.3f, SRMR = %.3f\n",
              n, fm["chisq"], fm["pvalue"], fm["cfi"], fm["rmsea"], fm["srmr"]))
}
