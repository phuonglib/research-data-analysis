# =====================================================================
# Post 26. Structural model (SEM) for repurchase intention on Marketplace X.
# AMOS-like settings: ML, FIML (Estimate means and intercepts),
# first loading of each factor fixed at 1, structural residuals d1-d3.
# Run:  LANG=C.UTF-8 Rscript structural_model.R
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]
measurement <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
structural <- '
  VALUE  ~ CONFIRM
  SATISF ~ CONFIRM + VALUE
  INTENT ~ CONFIRM + VALUE + SATISF + TRUST
  CONFIRM ~~ TRUST'
cfa_fit <- cfa(measurement, data = x, missing = "ml")
sem_fit <- sem(paste(measurement, structural), data = x, missing = "ml")
fm <- c("npar", "chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr", "aic", "bic")
t <- rbind(CFA = fitMeasures(cfa_fit, fm), SEM = fitMeasures(sem_fit, fm))
print(round(t, 3)); write.csv(round(t, 4), file.path(here, "fit_cfa_sem.csv"))
print(anova(cfa_fit, sem_fit))
pe <- parameterEstimates(sem_fit, standardized = TRUE)
paths <- subset(pe, op == "~")[, c("lhs", "rhs", "est", "se", "z", "pvalue", "std.all")]
print(paths, digits = 3); write.csv(paths, file.path(here, "path_coefficients.csv"), row.names = FALSE)
r2 <- lavInspect(sem_fit, "r2")[c("VALUE", "SATISF", "INTENT")]; print(round(r2, 3))
write.csv(data.frame(variable = names(r2), r2 = r2), file.path(here, "r2.csv"), row.names = FALSE)
cv <- subset(pe, op == "~~" & lhs == "CONFIRM" & rhs == "TRUST"); print(cv[, c("est", "pvalue", "std.all")])
# Loadings barely change from the CFA
l1 <- subset(standardizedSolution(cfa_fit), op == "=~")$est.std
l2 <- subset(standardizedSolution(sem_fit), op == "=~")$est.std
cat("Largest loading difference CFA - SEM:", round(max(abs(l1 - l2)), 4), "\n")
# Structural residuals (standardized variance = 1 - R2)
print(subset(standardizedSolution(sem_fit), op == "~~" & lhs %in% c("VALUE", "SATISF", "INTENT") & lhs == rhs)[, c("lhs", "est.std")])
# Total effect of CONFIRM on INTENT (standardized, delta method)
tot <- sem(paste(measurement, '
  VALUE  ~ a*CONFIRM
  SATISF ~ b*CONFIRM + c*VALUE
  INTENT ~ h4*CONFIRM + e*VALUE + f*SATISF + TRUST
  CONFIRM ~~ TRUST
  total := h4 + a*e + b*f + a*c*f'), data = x, missing = "ml")
print(subset(standardizedSolution(tot), op == ":=")[, c("lhs", "est.std", "se", "pvalue")])
# Modification indices for the omitted structural paths
mi <- modindices(sem_fit)
print(subset(mi, op == "~" & lhs %in% c("VALUE", "SATISF", "INTENT", "CONFIRM", "TRUST"))[, c("lhs", "op", "rhs", "mi", "sepc.all")], digits = 3)

# Common mistake: leaving out the covariance between the two exogenous factors (AMOS then fixes it at 0)
sem_nocov <- sem(paste(measurement, sub("CONFIRM ~~ TRUST", "CONFIRM ~~ 0*TRUST", structural)), data = x, missing = "ml")
cat("\nCovariance CONFIRM-TRUST left out:\n")
nc <- fitMeasures(sem_nocov, c("chisq", "df", "cfi", "rmsea", "srmr")); print(round(nc, 3))
write.csv(as.data.frame(as.list(round(nc, 4))), file.path(here, "fit_no_covariance.csv"), row.names = FALSE)
print(anova(sem_fit, sem_nocov))
