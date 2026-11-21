# =====================================================================
# Post 29. Multigroup analysis by gender.
# Step 1: measurement invariance (configural -> metric -> scalar)
# Step 2: structural invariance (the 7 path coefficients constrained equal)
# Step 3: compare each path (1-df chi-square difference test and the
#          critical ratio of the difference, as in AMOS)
# Two ways of handling missing data: FIML (as JASP) and complete cases (as AMOS)
# Run: LANG=C.UTF-8 Rscript multigroup.R
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
d <- d[d$GENDER %in% 1:2, c("GENDER", items)]             # drop the 5 respondents who chose "Other"
d$GROUP <- ifelse(d$GENDER == 1, "Male", "Female")
cat("Group sizes (FIML):"); print(table(d$GROUP))
dd <- na.omit(d); cat("Group sizes (complete cases):"); print(table(dd$GROUP))

model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
  INTENT  ~ CONFIRM + VALUE + SATISF + TRUST
  CONFIRM ~~ TRUST'
paths <- c("VALUE~CONFIRM", "SATISF~CONFIRM", "SATISF~VALUE", "INTENT~CONFIRM",
           "INTENT~VALUE", "INTENT~SATISF", "INTENT~TRUST")
hyp <- paste0("H", 1:7)
indices <- c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr")
glab <- c("Male", "Female")                                 # group 1 = Male (AMOS order), group 2 = Female

fit_models <- function(dat, miss) {
  f <- function(...) sem(model, data = dat, group = "GROUP", group.label = glab, missing = miss, ...)
  m <- list(
    "M1 Configural" = f(),
    "M2 Metric (loadings)" = f(group.equal = "loadings"),
    "M3 Scalar (loadings + intercepts)" = f(group.equal = c("loadings", "intercepts")),
    "M4 Structural (loadings + paths)" = f(group.equal = c("loadings", "regressions")))
  tab <- t(sapply(m, fitMeasures, indices))
  cmp <- function(a, b) { t <- anova(m[[a]], m[[b]]); c(dchisq = t[2, "Chisq diff"], ddf = t[2, "Df diff"], p = t[2, "Pr(>Chisq)"]) }
  cm <- rbind("M2 vs M1" = cmp(1, 2), "M3 vs M2" = cmp(2, 3), "M4 vs M2" = cmp(2, 4))
  dif <- function(k) c(tab[2, k] - tab[1, k], tab[3, k] - tab[2, k], tab[4, k] - tab[2, k])
  cm <- cbind(cm, dCFI = dif("cfi"), dRMSEA = dif("rmsea"), dSRMR = dif("srmr"))
  list(m = m, tab = tab, cm = cm)
}

# Constrain one path: rewrite the syntax with the label c(a,a) on path i
model_one_equal <- function(i) {
  lhs <- sub("~.*", "", paths[i]); rhs <- sub(".*~", "", paths[i])
  s <- model
  line <- regmatches(s, regexpr(paste0("\n  ", lhs, " +~ [^\n]*"), s))
  new_line <- sub(paste0("(~ |\\+ )", rhs, "(\\b)"), paste0("\\1c(a,a)*", rhs, "\\2"), line)
  sub(line, new_line, s, fixed = TRUE)
}

analyse <- function(dat, miss, title) {
  cat("\n==================", title, "==================\n")
  r <- fit_models(dat, miss)
  print(round(r$tab, 3)); print(round(r$cm, 4))
  m2 <- r$m[[2]]
  one <- t(sapply(seq_along(paths), function(i) {
    mi <- sem(model_one_equal(i), data = dat, group = "GROUP", group.label = glab, missing = miss, group.equal = "loadings")
    t <- anova(m2, mi); c(dchisq = t[2, "Chisq diff"], ddf = t[2, "Df diff"], p = t[2, "Pr(>Chisq)"])
  }))
  # Coefficients per group from M2 + critical ratio of the difference (as AMOS Critical ratios for differences)
  pe <- parameterEstimates(m2, standardized = TRUE)
  co <- t(sapply(paths, function(p) {
    lhs <- sub("~.*", "", p); rhs <- sub(".*~", "", p)
    a <- pe[pe$lhs == lhs & pe$rhs == rhs & pe$op == "~", ]
    V <- vcov(m2); nm <- paste0(lhs, "~", rhs, c("", ".g2"))
    v <- V[nm[1], nm[1]] + V[nm[2], nm[2]] - 2 * V[nm[1], nm[2]]
    c(B_male = a$est[a$group == 1], se_male = a$se[a$group == 1], beta_male = a$std.all[a$group == 1], p_male = a$pvalue[a$group == 1],
      B_female = a$est[a$group == 2], se_female = a$se[a$group == 2], beta_female = a$std.all[a$group == 2], p_female = a$pvalue[a$group == 2],
      cr_diff = (a$est[a$group == 2] - a$est[a$group == 1]) / sqrt(v))   # (Female - Male) / SE, AMOS sign
  }))
  res <- data.frame(H = hyp, path = paths, co, one)
  print(res, digits = 3)
  cat("Group 1 =", lavInspect(m2, "group.label")[1], "\n")
  print(round(sapply(lavInspect(m2, "r2"), function(z) z[c("VALUE", "SATISF", "INTENT")]), 3))
  lt <- lavTestScore(r$m[[4]])$uni; print(lt[order(-lt$X2), ][1:7, ], digits = 3)
  list(r = r, res = res)
}

res_fiml <- analyse(d, "ml", "FIML (as JASP)")
res_cc   <- analyse(dd, "listwise", "Complete cases (as AMOS)")

save_csv <- function(k, tag) {
  b <- data.frame(model = rownames(k$r$tab), k$r$tab, row.names = NULL)
  write.csv(b, file.path(here, paste0("invariance_", tag, ".csv")), row.names = FALSE)
  s <- data.frame(comparison = rownames(k$r$cm), k$r$cm, row.names = NULL)
  write.csv(s, file.path(here, paste0("comparison_", tag, ".csv")), row.names = FALSE)
  write.csv(k$res, file.path(here, paste0("paths_", tag, ".csv")), row.names = FALSE)
}
save_csv(res_fiml, "fiml"); save_csv(res_cc, "complete")

# Latent means (meaningful only under scalar invariance): group 2 (Female) relative to group 1 (Male)
m3 <- res_fiml$r$m[[3]]
lm <- subset(parameterEstimates(m3), op == "~1" & lhs %in% c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT") & group == 2)
cat("\nLatent means of group 2 (Female) relative to group 1 (Male), FIML, M3:\n"); print(lm[, c("lhs", "est", "se", "z", "pvalue")], digits = 3)
write.csv(lm[, c("lhs", "est", "se", "z", "pvalue")], file.path(here, "latent_means.csv"), row.names = FALSE)

# Score test on M2: which loading differs most between the groups
m2 <- res_fiml$r$m[[2]]; lt <- lavTestScore(m2)$uni
pt <- parTable(m2); plab <- function(pl) { r <- pt[pt$plabel == pl, ]; paste0(r$lhs, r$op, r$rhs) }
lt$parameter <- sapply(lt$lhs, plab)
cat("\nScore test on M2 (metric invariance):\n"); print(lt[order(-lt$X2), c("parameter", "X2", "df", "p.value")][1:5, ], digits = 3)
write.csv(lt[order(-lt$X2), c("parameter", "X2", "df", "p.value")], file.path(here, "score_test_metric.csv"), row.names = FALSE)

# AMOS-style model with Estimate means on: Structural weights = loadings + intercepts + paths
m5 <- function(dat, miss) sem(model, data = dat, group = "GROUP", group.label = glab, missing = miss,
                              group.equal = c("loadings", "intercepts", "regressions"))
for (k in list(list(d, "ml", "fiml", res_fiml), list(dd, "listwise", "complete", res_cc))) {
  f5 <- m5(k[[1]], k[[2]]); t <- anova(k[[4]]$r$m[[3]], f5)
  r <- c(fitMeasures(f5, indices), dchisq = t[2, "Chisq diff"], ddf = t[2, "Df diff"], p = t[2, "Pr(>Chisq)"])
  cat("\nM5 (scalar + paths),", k[[3]], ":\n"); print(round(r, 4))
  write.csv(as.data.frame(t(r)), file.path(here, paste0("m5_", k[[3]], ".csv")), row.names = FALSE)
}
