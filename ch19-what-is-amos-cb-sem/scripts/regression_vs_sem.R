# =====================================================================
# Post 19. Regression on composite (mean) scores (SPSS/PSPP) compared with
# CB-SEM (latent variable model) on the same sample data.
# Data: marketplace_x_analysis.csv (267 respondents).
# Run from this folder:  LANG=C.UTF-8 Rscript regression_vs_sem.R
# Needs: R 4.x, package lavaan (install.packages("lavaan"))
# lavaan uses maximum likelihood (ML) estimation like AMOS; missing data are
# handled with FIML, equivalent to the AMOS option "Estimate means and intercepts".
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_analysis.csv"))

# Composite scores (means of the items) carry the construct names
d$CONFIRM <- d$CONF; d$VALUE <- d$PV; d$SATISF <- d$SAT; d$TRUST <- d$TRU; d$INTENT <- d$RI

# 1. Regression on composite scores (as in Post 14), standardized variables to get beta
z <- as.data.frame(scale(d[, c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT")]))
m1 <- lm(VALUE ~ CONFIRM, z); m2 <- lm(SATISF ~ CONFIRM + VALUE, z)
m3 <- lm(INTENT ~ CONFIRM + VALUE + SATISF + TRUST, z)
cat("\n=== Regression on composite scores (standardized beta) ===\n")
cat("N =", nobs(m3), "\n")
print(round(coef(m1)[-1], 3)); print(round(coef(m2)[-1], 3)); print(round(coef(m3)[-1], 3))
cat("R2:", round(summary(m1)$r.squared, 3), round(summary(m2)$r.squared, 3), round(summary(m3)$r.squared, 3), "\n")

# 2. CB-SEM: measurement model + structural model
model <- '
  # Measurement model
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  # Structural model
  VALUE  ~ CONFIRM
  SATISF ~ CONFIRM + VALUE
  INTENT ~ CONFIRM + VALUE + SATISF + TRUST
'
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), paste0("TRU", 1:3), "TRU4R", paste0("RI", 1:4))
x <- d[, items]
cat("\nMissing cells:", sum(is.na(x)), "in", sum(!complete.cases(x)), "respondents\n")
fit <- sem(model, data = x, estimator = "ML", missing = "ml")
cat("\n=== CB-SEM ===\n")
cat("N =", lavInspect(fit, "nobs"), "; free parameters (excluding means/intercepts):",
    fitMeasures(fit, "npar") - length(items), "\n")
print(round(fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr")), 3))
pe <- standardizedSolution(fit)
print(subset(pe, op == "~")[, c("lhs", "op", "rhs", "est.std", "se", "pvalue")], digits = 3)
cat("R2:\n"); print(round(lavInspect(fit, "r2")[c("VALUE", "SATISF", "INTENT")], 3))
cat("Standardized loadings:", paste(range(round(subset(pe, op == "=~")$est.std, 2)), collapse = " to "), "\n")

# Save the comparison table for Figure 4
ss <- subset(pe, op == "~")
reg <- c(coef(m1)[-1], coef(m2)[-1], coef(m3)[-1])
p_reg <- c(summary(m1)$coef[-1, 4], summary(m2)$coef[-1, 4], summary(m3)$coef[-1, 4])
out <- data.frame(path = paste(ss$rhs, "->", ss$lhs), regression = round(reg, 3), p_regression = round(p_reg, 4),
                  sem = round(ss$est.std, 3), p_sem = round(ss$pvalue, 4))
print(out)
write.csv(out, file.path(here, "regression_vs_sem.csv"), row.names = FALSE)
