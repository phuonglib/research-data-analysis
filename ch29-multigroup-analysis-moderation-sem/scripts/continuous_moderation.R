# =====================================================================
# Post 29 (part 2). A continuous moderator in CB-SEM:
# does TRUST moderate the effect SATISF -> INTENT?
# Method: product indicators, 4 matched pairs,
# double-mean centering (Lin et al., 2010).
# Also compares a median split (not recommended).
# Run: LANG=C.UTF-8 Rscript continuous_moderation.R
# =====================================================================
library(lavaan); library(semTools)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
sat <- paste0("SAT", 1:4); tru <- c("TRU1", "TRU2", "TRU3", "TRU4R")
# Double centering: subtract each item's mean, multiply the pairs, then subtract the mean of each product
dc <- d
for (v in c(sat, tru)) dc[[v]] <- d[[v]] - mean(d[[v]], na.rm = TRUE)
for (i in 1:4) {
  p <- dc[[sat[i]]] * dc[[tru[i]]]
  d[[paste0("SATxTRU", i)]] <- p - mean(p, na.rm = TRUE)
}
# Check with semTools::indProd (must give the same result)
chk <- indProd(read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv")), var1 = sat, var2 = tru,
               match = TRUE, meanC = TRUE, residualC = FALSE, doubleMC = TRUE, namesProd = paste0("chk", 1:4))
cat("Largest difference from indProd:", max(abs(as.matrix(chk[, paste0("chk", 1:4)]) - as.matrix(d[, paste0("SATxTRU", 1:4)])), na.rm = TRUE), "\n")

model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  SATxTRU =~ SATxTRU1 + SATxTRU2 + SATxTRU3 + SATxTRU4
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
  INTENT  ~ CONFIRM + VALUE + h6*SATISF + h7*TRUST + h8*SATxTRU
  CONFIRM ~~ TRUST
  CONFIRM ~~ SATxTRU
  TRUST   ~~ SATxTRU
  # matched pairs (SAT1 x TRU1, SAT2 x TRU2...): no two products share an original item,
  # so their errors are not allowed to correlate'
f <- sem(model, data = d, missing = "ml")
fm <- fitMeasures(f, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr")); print(round(fm, 3))
pe <- subset(parameterEstimates(f, standardized = TRUE), op == "~" & lhs == "INTENT")
print(pe[, c("rhs", "label", "est", "se", "z", "pvalue", "ci.lower", "ci.upper", "std.all")], digits = 3)
r2 <- lavInspect(f, "r2")["INTENT"]; cat("R2 INTENT (with interaction):", round(r2, 3), "\n")
# Model without the interaction (h8 = 0) for the change in R2
f0 <- sem(sub("h8\\*SATxTRU", "0*SATxTRU", model), data = d, missing = "ml")
r20 <- lavInspect(f0, "r2")["INTENT"]; cat("R2 INTENT (h8 = 0):", round(r20, 3), " f2 =", round((r2 - r20) / (1 - r2), 4), "\n")
print(anova(f0, f))
# Simple slopes of SATISF at TRUST = -1 SD, 0, +1 SD
v_tru <- lavInspect(f, "cov.lv")["TRUST", "TRUST"]; sd_tru <- sqrt(v_tru)
cat("Variance of TRUST (vTRU):", round(v_tru, 4), "\n")
b <- coef(f); V <- vcov(f)
slopes <- t(sapply(c(-1, 0, 1), function(k) {
  w <- k * sd_tru; est <- b["h6"] + b["h8"] * w
  se <- sqrt(V["h6", "h6"] + w^2 * V["h8", "h8"] + 2 * w * V["h6", "h8"])
  c(level = k, TRUST = w, slope = est, se = se, z = est / se, p = 2 * pnorm(-abs(est / se)))
}))
colnames(slopes) <- c("level", "TRUST", "slope", "se", "z", "p")
print(round(slopes, 4))

# Median split (shown to illustrate why it should be avoided)
d$TRU_mean <- rowMeans(d[, tru], na.rm = TRUE)
d$TRU_GROUP <- ifelse(d$TRU_mean > median(d$TRU_mean), "High", "Low")
cat("Median of TRU:", median(d$TRU_mean), "\n"); print(table(d$TRU_GROUP))
model2 <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
  INTENT  ~ CONFIRM + VALUE + c(a1, a2)*SATISF'
g1 <- sem(model2, data = d, group = "TRU_GROUP", group.label = c("Low", "High"), missing = "ml", group.equal = "loadings")
g0 <- sem(sub("c\\(a1, a2\\)", "c(a, a)", model2), data = d, group = "TRU_GROUP", group.label = c("Low", "High"),
          missing = "ml", group.equal = "loadings")
p2 <- subset(parameterEstimates(g1), label %in% c("a1", "a2")); print(p2[, c("group", "est", "se", "pvalue")], digits = 3)
print(anova(g0, g1))
out <- data.frame(pe[, c("rhs", "est", "se", "z", "pvalue", "ci.lower", "ci.upper", "std.all")])
write.csv(out, file.path(here, "continuous_moderation.csv"), row.names = FALSE)
write.csv(as.data.frame(slopes), file.path(here, "simple_slopes.csv"), row.names = FALSE)
# Compare with the product indicators made by prepare_post29_data.sps (PSPP)
ps <- read.csv(file.path(here, "..", "data", "marketplace_x_product.csv"))
cat("Largest difference from PSPP:", max(abs(as.matrix(ps[, paste0("SATxTRU", 1:4)]) - as.matrix(d[, paste0("SATxTRU", 1:4)])), na.rm = TRUE), "\n")

# Complete cases (254 respondents, as AMOS) with the product indicators of marketplace_x_product (centered on 267)
cc <- na.omit(ps[, c(paste0("CONF", 1:4), paste0("PV", 1:4), sat, tru, paste0("RI", 1:4), paste0("SATxTRU", 1:4))])
fc <- sem(model, data = cc)
cat("\nComplete cases: N =", nrow(cc), "\n"); print(round(fitMeasures(fc, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr")), 3))
pec <- subset(parameterEstimates(fc, standardized = TRUE), op == "~" & lhs == "INTENT")
print(pec[, c("rhs", "est", "se", "z", "pvalue", "std.all")], digits = 3)
write.csv(pec[, c("rhs", "est", "se", "z", "pvalue", "std.all")], file.path(here, "continuous_moderation_complete.csv"), row.names = FALSE)
