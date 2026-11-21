# =====================================================================
# Post 22. Confirmatory factor analysis (CFA) of the five scales.
# Run:      LANG=C.UTF-8 Rscript cfa_5_factors.R
# Requires: R 4.x, package lavaan
# Same settings as AMOS: ML, first loading of each factor fixed to 1,
# FIML for missing data (Estimate means and intercepts).
# Mardia's test and the Bollen-Stine bootstrap use the 254 complete
# respondents, because AMOS computes these two results only when the
# data have no missing cells.
# =====================================================================
library(lavaan)
set.seed(2026)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R",
           paste0("RI", 1:4))
x <- d[, items]; xc <- na.omit(x)

model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
'
# ---- 1. Normality (as in AMOS "Assessment of normality") ----------------
n <- nrow(xc); p <- ncol(xc)
sk <- sapply(xc, function(v) { z <- v - mean(v); mean(z^3) / mean(z^2)^1.5 })
ku <- sapply(xc, function(v) { z <- v - mean(v); mean(z^4) / mean(z^2)^2 - 3 })
normal <- data.frame(item = items, min = sapply(xc, min), max = sapply(xc, max),
                     skew = round(sk, 3), cr_skew = round(sk / sqrt(6 / n), 3),
                     kurtosis = round(ku, 3), cr_kurt = round(ku / sqrt(24 / n), 3))
S <- cov(xc) * (n - 1) / n
Z <- scale(xc, scale = FALSE)
D2 <- rowSums((Z %*% solve(S)) * Z)
b2p <- mean(D2^2)
mardia <- b2p - p * (p + 2)
cr_mardia <- mardia / sqrt(8 * p * (p + 2) / n)
cat(sprintf("N = %d. Mardia (multivariate kurtosis) = %.3f, c.r. = %.3f\n", n, mardia, cr_mardia))
print(normal, row.names = FALSE)
write.csv(rbind(normal, data.frame(item = "Multivariate", min = NA, max = NA, skew = NA, cr_skew = NA,
                                   kurtosis = round(mardia, 3), cr_kurt = round(cr_mardia, 3))),
          file.path(here, "normality.csv"), row.names = FALSE, fileEncoding = "UTF-8")
# Check of the JASP values (Mardia's Coefficients table): JASP uses the covariance matrix with N - 1
Su <- cov(xc)
D2u <- rowSums((Z %*% solve(Su)) * Z)
b2u <- mean(D2u^2)
z_u <- (b2u - p * (p + 2)) / sqrt(8 * p * (p + 2) / n)
G <- Z %*% solve(Su) %*% t(Z)
b1u <- sum(G^3) / n^2
cat(sprintf("JASP-style (N - 1): kurtosis b2 = %.2f, z = %.3f; skewness b1 = %.2f, chi-square = %.0f, df = %d\n",
            b2u, z_u, b1u, n * b1u / 6, p * (p + 1) * (p + 2) / 6))
# Observations farthest from the centroid (Mahalanobis d2, as in AMOS)
d2s <- D2 * n / (n - 1)  # AMOS uses the unbiased sample covariance
o <- order(d2s, decreasing = TRUE)[1:5]
p1 <- pchisq(d2s[o], p, lower.tail = FALSE)
cat("Five observations farthest from the centroid (ID, d2, p1):\n")
print(data.frame(ID = d$ID[complete.cases(x)][o], d2 = round(d2s[o], 2), p1 = round(p1, 3)))

# ---- 2. CFA with FIML on 267 respondents --------------------------------
fit <- cfa(model, data = x, estimator = "ML", missing = "ml")
print(round(fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower",
                               "rmsea.ci.upper", "srmr")), 3))
pe <- parameterEstimates(fit, standardized = TRUE)
loadings <- subset(pe, op == "=~")[, c("lhs", "rhs", "est", "se", "z", "pvalue", "std.all")]
loadings$r2 <- loadings$std.all^2
print(loadings, digits = 3, row.names = FALSE)
write.csv(loadings, file.path(here, "factor_loadings.csv"), row.names = FALSE, fileEncoding = "UTF-8")
fc <- subset(pe, op == "~~" & lhs != rhs & lhs %in% c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT"))
print(fc[, c("lhs", "rhs", "est", "pvalue", "std.all")], digits = 3, row.names = FALSE)
write.csv(fc[, c("lhs", "rhs", "est", "se", "pvalue", "std.all")], file.path(here, "factor_correlations.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
pv <- subset(pe, op == "~~" & lhs == rhs)
cat("Negative variances (Heywood)?", any(pv$est < 0), "\n")
rv <- subset(pe, op == "~~" & lhs == rhs & lhs %in% items)
cat("Smallest standardized error variance:", rv$lhs[which.min(rv$std.all)], round(min(rv$std.all), 3), "\n")

# ---- 3. Modification indices and standardized residuals -----------------
mi <- modindices(fit, sort. = TRUE, minimum.value = 4)
print(head(mi[, c("lhs", "op", "rhs", "mi", "epc", "sepc.all")], 10), digits = 3)
write.csv(head(mi[, c("lhs", "op", "rhs", "mi", "epc", "sepc.all")], 10), file.path(here, "modification_indices.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
rs <- lavResiduals(fit)$cov.z
cat("Largest standardized residual (absolute):", round(max(abs(rs[lower.tri(rs)])), 2), "\n")
cat("Standardized residuals above 2.58:", sum(abs(rs[lower.tri(rs)]) > 2.58), "of", sum(lower.tri(rs)), "\n")

# ---- 4. Bollen-Stine bootstrap on 254 complete respondents --------------
fit_c <- cfa(model, data = xc, estimator = "ML")
bs <- bootstrapLavaan(fit_c, R = 2000, type = "bollen.stine", FUN = fitMeasures, fit.measures = "chisq")
p_bs <- (1 + sum(bs[, 1] >= fitMeasures(fit_c, "chisq"))) / (2000 + 1)
cat(sprintf("Bollen-Stine: chi-square (N = 254) = %.2f, bootstrap p = %.3f (2000 samples)\n",
            fitMeasures(fit_c, "chisq"), p_bs))
