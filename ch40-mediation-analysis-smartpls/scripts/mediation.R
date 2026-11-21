# =====================================================================
# Post 40. Mediation analysis of the Marketplace X model (PLS-SEM): specific indirect effects,
# total indirect effects, total effects. Bootstrap with 5000 samples, 95% percentile confidence intervals.
# Specific indirect effect = product of the path coefficients, computed in every bootstrap sample.
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 39.
# Package: cSEM 0.7.1. Results vary slightly with the random bootstrap samples (seed 2026).
# Run from this folder:  LANG=C.UTF-8 Rscript mediation.R
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
B <- bs$Estimates$Estimates_resample$Estimates1$Path_estimates$Resampled
O <- bs$Estimates$Estimates_resample$Estimates1$Path_estimates$Original
paths <- list(
  "CONFIRM -> VALUE -> SATISF"           = c("VALUE ~ CONFIRM", "SATISF ~ VALUE"),
  "CONFIRM -> VALUE -> INTENT"           = c("VALUE ~ CONFIRM", "INTENT ~ VALUE"),
  "CONFIRM -> SATISF -> INTENT"          = c("SATISF ~ CONFIRM", "INTENT ~ SATISF"),
  "VALUE -> SATISF -> INTENT"            = c("SATISF ~ VALUE", "INTENT ~ SATISF"),
  "CONFIRM -> VALUE -> SATISF -> INTENT" = c("VALUE ~ CONFIRM", "SATISF ~ VALUE", "INTENT ~ SATISF"))
summ <- function(name, orig, boot) {
  p <- 2 * min(mean(boot <= 0), mean(boot >= 0))  # two-sided p from the bootstrap distribution
  data.frame(effect = name, estimate = orig, mean = mean(boot), std_dev = sd(boot),
             t = abs(orig) / sd(boot), p_bootstrap = p,
             ci_lower = unname(quantile(boot, .025)), ci_upper = unname(quantile(boot, .975)))
}
specific <- do.call(rbind, lapply(names(paths), function(k)
  summ(k, prod(O[paths[[k]]]), apply(B[, paths[[k]], drop = FALSE], 1, prod))))
ind <- function(ks) { o <- Reduce(`+`, lapply(ks, function(k) prod(O[paths[[k]]])))
  b <- Reduce(`+`, lapply(ks, function(k) apply(B[, paths[[k]], drop = FALSE], 1, prod))); list(o, b) }
total_ind <- rbind(
  do.call(summ, c("Total indirect CONFIRM -> INTENT", ind(names(paths)[c(2, 3, 5)]))),
  do.call(summ, c("Total indirect VALUE -> INTENT", ind(names(paths)[4]))),
  do.call(summ, c("Total indirect CONFIRM -> SATISF", ind(names(paths)[1]))))
g1 <- ind(names(paths)[c(2, 3, 5)]); g2 <- ind(names(paths)[4])
total <- rbind(summ("Total effect CONFIRM -> INTENT", g1[[1]] + O["INTENT ~ CONFIRM"], g1[[2]] + B[, "INTENT ~ CONFIRM"]),
               summ("Total effect VALUE -> INTENT", g2[[1]] + O["INTENT ~ VALUE"], g2[[2]] + B[, "INTENT ~ VALUE"]))
direct <- rbind(summ("Direct CONFIRM -> INTENT", O["INTENT ~ CONFIRM"], B[, "INTENT ~ CONFIRM"]),
                summ("Direct VALUE -> INTENT", O["INTENT ~ VALUE"], B[, "INTENT ~ VALUE"]))
res <- rbind(specific, total_ind, total, direct)
options(width = 200); print(res, digits = 3, row.names = FALSE)
# VAF: share of the total effect that is indirect
cat("VAF CONFIRM -> INTENT:", round(g1[[1]] / (g1[[1]] + O["INTENT ~ CONFIRM"]), 3), "\n")
cat("VAF VALUE -> INTENT:", round(g2[[1]] / (g2[[1]] + O["INTENT ~ VALUE"]), 3), "\n")
write.csv(res, "mediation.csv", row.names = FALSE)
