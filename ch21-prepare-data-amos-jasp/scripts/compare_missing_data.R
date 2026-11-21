# =====================================================================
# Post 21. Missing data before running CFA/SEM:
#   1. Little's (1988) MCAR test
#   2. Comparison of three ways of handling missing data on the
#      five-factor measurement model: listwise deletion, FIML,
#      mean substitution.
# Run:   LANG=C.UTF-8 Rscript compare_missing_data.R   (from the scripts/ folder)
# Needs: R 4.x, package lavaan
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R",
           paste0("RI", 1:4))
x <- d[, items]

cat("Missing cells:", sum(is.na(x)), "of", prod(dim(x)), sprintf("(%.2f%%)\n", 100 * mean(is.na(x))))
cat("Respondents with at least one blank item:", sum(!complete.cases(x)), "\n")
pattern <- apply(is.na(x), 1, function(r) paste(as.integer(r), collapse = ""))
cat("Missing-data patterns (including the complete pattern):", length(unique(pattern)), "\n")

# ---- 1. Little's MCAR test -----------------------------------------------
# Means and covariances estimated by ML with missing data (EM/FIML)
saturated <- lavCor(x, missing = "ml", output = "fit", estimator = "ML")
mu <- lavInspect(saturated, "implied")$mean
S <- lavInspect(saturated, "implied")$cov
d2 <- 0; df <- 0
for (m in unique(pattern)) {
  rows <- which(pattern == m)
  obs <- which(!is.na(x[rows[1], ]))
  means <- colMeans(x[rows, obs, drop = FALSE])
  dev <- means - mu[obs]
  d2 <- d2 + length(rows) * as.numeric(t(dev) %*% solve(S[obs, obs]) %*% dev)
  df <- df + length(obs)
}
df <- df - ncol(x)
cat(sprintf("Little's MCAR test: chi-square = %.2f, df = %d, p = %.3f\n", d2, df, pchisq(d2, df, lower.tail = FALSE)))

# ---- 2. Compare three ways of handling missing data ----------------------
model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
'
mean_sub <- x
for (v in items) mean_sub[is.na(mean_sub[[v]]), v] <- mean(x[[v]], na.rm = TRUE)

fits <- list(
  "Listwise deletion" = cfa(model, data = x, estimator = "ML", missing = "listwise"),
  "FIML"              = cfa(model, data = x, estimator = "ML", missing = "ml"),
  "Mean substitution" = cfa(model, data = mean_sub, estimator = "ML")
)
res <- do.call(rbind, lapply(names(fits), function(k) {
  f <- fits[[k]]
  fm <- fitMeasures(f, c("chisq", "df", "cfi", "tli", "rmsea", "srmr"))
  load <- subset(standardizedSolution(f), op == "=~")$est.std
  data.frame(method = k, N = lavInspect(f, "nobs"), chisq = round(fm[["chisq"]], 2), df = fm[["df"]],
             cfi = round(fm[["cfi"]], 3), tli = round(fm[["tli"]], 3), rmsea = round(fm[["rmsea"]], 3),
             srmr = round(fm[["srmr"]], 3), loading_min = round(min(load), 3), loading_max = round(max(load), 3),
             loading_SAT2 = round(load[10], 3))
}))
print(res, row.names = FALSE)
write.csv(res, file.path(here, "compare_missing_data.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Largest difference in standardized loadings compared with FIML
load <- sapply(fits, function(f) subset(standardizedSolution(f), op == "=~")$est.std)
cat("Largest difference in standardized loadings compared with FIML:\n")
print(round(apply(abs(load - load[, "FIML"]), 2, max), 4))
