# =====================================================================
# Post 38. Out-of-sample predictive power of the Marketplace X model: PLSpredict (Shmueli et al., 2016, 2019).
# 10 folds, 10 repetitions, PLS-SEM compared with a linear regression model (LM) as the benchmark.
# Metrics: Q2predict, RMSE, MAE for each indicator of the endogenous constructs (VALUE, SATISF, INTENT).
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 37.
# Package: cSEM 0.7.1. Results vary slightly with the random fold assignment.
# Note: with .r > 1, cSEM 0.7.1 does not accept .seed, and when .seed is NULL its internal resampleData()
# calls set.seed(NULL) and draws a fresh seed, so set.seed(2026) below does NOT fix the folds. Each run
# therefore differs from the previous one in the third decimal place. plspredict.csv in this folder is the
# run reported in Post 38 (indicator names translated); running this script overwrites it with a new run.
# Run from this folder:  LANG=C.UTF-8 Rscript plspredict.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- na.omit(d[, items]); cat("N =", nrow(x), "\n")
model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
  INTENT  ~ CONFIRM + VALUE + SATISF + TRUST'
fit <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
set.seed(2026)
p <- predict(fit, .benchmark = "lm", .cv_folds = 10, .r = 10, .disattenuate = FALSE)
res <- p$Prediction_metrics
print(res, digits = 3)
write.csv(res, "plspredict.csv", row.names = FALSE)
