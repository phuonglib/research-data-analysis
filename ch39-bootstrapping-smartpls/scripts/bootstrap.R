# =====================================================================
# Post 39. Bootstrapping and the significance test of the seven paths of the Marketplace X model (PLS-SEM).
# 5000 bootstrap subsamples, 95% percentile confidence intervals, two-tailed test.
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 38.
# Package: cSEM 0.7.1. Results vary slightly with the random bootstrap samples (seed 2026).
# Run from this folder:  LANG=C.UTF-8 Rscript bootstrap.R
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
bs <- resamplecSEMResults(fit, .R = 5000, .seed = 2026)
s <- summarize(bs, .ci = "CI_percentile")$Estimates$Path_estimates
boot <- bs$Estimates$Estimates_resample$Estimates1$Path_estimates$Resampled
res <- data.frame(path = s$Name, coefficient = s$Estimate, bootstrap_mean = colMeans(boot[, s$Name]),
                  std_dev = s$Std_err, t = s$t_stat, p = s$p_value,
                  ci_lower = s[["CI_percentile.95%L"]], ci_upper = s[["CI_percentile.95%U"]])
options(width = 200); print(res, digits = 3, row.names = FALSE)
# Hand calculation of t: coefficient / bootstrap standard deviation
h7 <- res$path == "INTENT ~ TRUST"; cat("t by hand, H7:", round(res$coefficient[h7] / res$std_dev[h7], 3), "\n")
cat("Share of negative H4 coefficients:", mean(boot[, "INTENT ~ CONFIRM"] < 0), "\n")
cat("Smallest H7 coefficient:", round(min(boot[, "INTENT ~ TRUST"]), 3), "\n")
write.csv(res, "bootstrap_paths.csv", row.names = FALSE)
# Bootstrap distribution of two paths (for the distribution figure in the post): H4 and H7
write.csv(data.frame(H4 = boot[, "INTENT ~ CONFIRM"], H7 = boot[, "INTENT ~ TRUST"]),
          "bootstrap_distribution.csv", row.names = FALSE)
