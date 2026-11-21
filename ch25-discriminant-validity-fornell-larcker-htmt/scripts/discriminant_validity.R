# =====================================================================
# Post 25. Convergent and discriminant validity.
#   1. Fornell-Larcker: square root of AVE versus the correlations between factors
#   2. HTMT (Henseler et al., 2015) and bootstrap confidence intervals
#   3. Testing whether a correlation differs from 1 (chi-square model comparison)
# Run:  LANG=C.UTF-8 Rscript discriminant_validity.R   (from the scripts folder)
# AVE is computed here directly:
# AVE = mean of the squared standardized loadings from the same CFA and writes ave.csv.
# =====================================================================
library(lavaan); library(semTools)
set.seed(2026)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]
fac <- c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT")
model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
fit <- cfa(model, data = x, missing = "ml")
R <- lavInspect(fit, "cor.lv")[fac, fac]

# AVE from the standardized loadings (same formula as Post 24)
st <- subset(standardizedSolution(fit), op == "=~")
ave <- data.frame(construct = fac, AVE = sapply(fac, function(f) mean(st$est.std[st$lhs == f]^2)))
ave$sqrt_AVE <- sqrt(ave$AVE)
print(ave, digits = 4)
write.csv(ave, file.path(here, "ave.csv"), row.names = FALSE)

FL <- R; diag(FL) <- ave$sqrt_AVE
cat("Fornell-Larcker matrix (diagonal = square root of AVE):\n"); print(round(FL, 3))
write.csv(round(FL, 4), file.path(here, "fornell_larcker.csv"))

# HTMT on the data (pairwise correlations of the items)
H <- htmt(model, data = x, missing = "pairwise", htmt2 = FALSE)
cat("HTMT:\n"); print(round(H, 3))
write.csv(round(as.matrix(H), 4), file.path(here, "htmt.csv"))
H2 <- htmt(model, data = x, missing = "pairwise", htmt2 = TRUE)
cat("HTMT2 (geometric mean):\n"); print(round(H2, 4))

# Bootstrap 95% CI for HTMT (2000 samples, percentile)
B <- 2000; n <- nrow(x)
ds <- replicate(B, { i <- sample(n, n, TRUE); m <- as.matrix(htmt(model, data = x[i, ], missing = "pairwise", htmt2 = FALSE)); m[lower.tri(m)] })
ci <- t(apply(ds, 1, quantile, c(0.025, 0.975)))
idx <- which(lower.tri(as.matrix(H)), arr.ind = TRUE)
tab <- data.frame(pair = paste(rownames(H)[idx[, 1]], colnames(H)[idx[, 2]], sep = " - "),
                  htmt = as.matrix(H)[lower.tri(as.matrix(H))], low = ci[, 1], up = ci[, 2])
print(tab, digits = 3)
write.csv(tab, file.path(here, "htmt_bootstrap.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Test whether the VALUE-SATISF correlation equals 1 (constrained model)
m_con <- paste(model, '
  CONFIRM ~~ 1*CONFIRM
  VALUE ~~ 1*VALUE
  SATISF ~~ 1*SATISF
  TRUST ~~ 1*TRUST
  INTENT ~~ 1*INTENT')
m_con <- gsub("=~ ", "=~ NA*", m_con)
f0 <- cfa(m_con, data = x, missing = "ml")
f1 <- cfa(paste(m_con, "\n  VALUE ~~ 1*SATISF"), data = x, missing = "ml")
print(anova(f0, f1))
ss <- subset(standardizedSolution(fit), op == "~~" & lhs != rhs & lhs %in% fac)
print(ss[, c("lhs", "rhs", "est.std", "ci.lower", "ci.upper")], digits = 3)
