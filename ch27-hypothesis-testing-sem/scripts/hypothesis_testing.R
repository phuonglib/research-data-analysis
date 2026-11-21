# =====================================================================
# Post 27. Hypothesis testing in SEM and reading standardized coefficients.
#   1. Unstandardized and standardized coefficients, C.R., p, 95% CI
#   2. Bootstrap CIs (2000 samples, 254 complete respondents) as a robustness check
#   3. Effect size f-square of each predictor of INTENT
#   4. Comparing two coefficients: TRUST vs SATISF to INTENT
# Run:  LANG=C.UTF-8 Rscript hypothesis_testing.R
# =====================================================================
library(lavaan)
set.seed(2026)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]; xc <- na.omit(x)
mm <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
sm <- '
  VALUE  ~ h1*CONFIRM
  SATISF ~ h2*CONFIRM + h3*VALUE
  INTENT ~ h4*CONFIRM + h5*VALUE + h6*SATISF + h7*TRUST
  CONFIRM ~~ TRUST
  diff_TRU_SAT := h7 - h6'
fit <- sem(paste(mm, sm), data = x, missing = "ml")
pe <- parameterEstimates(fit, standardized = TRUE)
ss <- standardizedSolution(fit)
reg <- subset(pe, op == "~"); sreg <- subset(ss, op == "~")
tab <- data.frame(hypothesis = paste0("H", 1:7), path = paste(reg$rhs, "->", reg$lhs),
                  B = reg$est, SE = reg$se, CR = reg$z, p = reg$pvalue, B_low = reg$ci.lower, B_up = reg$ci.upper,
                  beta = sreg$est.std, beta_low = sreg$ci.lower, beta_up = sreg$ci.upper)
cat("N =", lavInspect(fit, "nobs"), " complete cases =", nrow(xc), "\n")
# Bootstrap on the complete-case data (as in AMOS)
fb <- sem(paste(mm, sm), data = xc, se = "bootstrap", bootstrap = 2000)
bb <- subset(parameterEstimates(fb, boot.ci.type = "perc"), op == "~")
tab$boot_low <- bb$ci.lower; tab$boot_up <- bb$ci.upper
print(tab, digits = 3, row.names = FALSE)
write.csv(tab, file.path(here, "hypotheses.csv"), row.names = FALSE)
cat("\nComparison h7 - h6 (unstandardized):\n"); print(subset(pe, op == ":=")[, c("est", "se", "z", "pvalue", "ci.lower", "ci.upper")])
cat("Standardized:\n"); print(subset(ss, op == ":=")[, c("est.std", "se", "z", "pvalue", "ci.lower", "ci.upper")])
# Wald test (equivalent)
print(lavTestWald(fit, "h7 == h6"))
# f-square for each predictor of INTENT
r2_full <- lavInspect(fit, "r2")["INTENT"]
f2 <- sapply(c("CONFIRM", "VALUE", "SATISF", "TRUST"), function(v) {
  sm2 <- sub(paste0(" \\+ h[0-9]\\*", v, "|h[0-9]\\*", v, " \\+ "), "", sub("diff_TRU_SAT := h7 - h6", "", sm))
  m2 <- sem(paste(mm, sm2), data = x, missing = "ml")
  r2 <- lavInspect(m2, "r2")["INTENT"]
  c(r2_dropped = unname(r2), f2 = unname((r2_full - r2) / (1 - r2_full)))
})
print(round(t(f2), 4)); cat("Full R2 of INTENT:", round(r2_full, 4), "\n")
write.csv(round(t(f2), 4), file.path(here, "f2.csv"))
