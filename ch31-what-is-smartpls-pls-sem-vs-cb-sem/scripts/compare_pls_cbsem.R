# =====================================================================
# Post 31. PLS-SEM, PLSc-SEM, CB-SEM and regression on mean scores
# for the Marketplace X model (254 respondents with complete data).
# Packages: cSEM (the package behind JASP's Partial Least Squares SEM module),
#           lavaan, foreign (reads the .sav file; ships with R).
# Run from this folder:  LANG=C.UTF-8 Rscript compare_pls_cbsem.R
# English run: R 4.6.2, cSEM 0.7.1, lavaan 0.7.3.
# =====================================================================
suppressMessages({ library(cSEM); library(lavaan) })
cat("cSEM", as.character(packageVersion("cSEM")), " lavaan", as.character(packageVersion("lavaan")), "\n")
d <- foreign::read.spss("../data/marketplace_x_sem_complete.sav", to.data.frame = TRUE, use.value.labels = FALSE)
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
paths <- c("VALUE ~ CONFIRM", "SATISF ~ CONFIRM", "SATISF ~ VALUE", "INTENT ~ CONFIRM",
           "INTENT ~ VALUE", "INTENT ~ SATISF", "INTENT ~ TRUST")

# 1. PLS-SEM (SmartPLS default: path weighting scheme) and PLSc-SEM
pls  <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
plsc <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = TRUE)
get_paths <- function(f) { p <- summarize(f)$Estimates$Path_estimates; setNames(p$Estimate, p$Name) }
get_loadings <- function(f) { p <- summarize(f)$Estimates$Loading_estimates; setNames(p$Estimate, p$Name) }
print(verify(pls))

# 2. CB-SEM (lavaan, ML) with the covariance CONFIRM ~~ TRUST as in Post 26
cb <- sem(paste0(model, "\n CONFIRM ~~ TRUST"), data = x)
sc <- standardizedSolution(cb)
cb_paths <- setNames(sc$est.std[sc$op == "~"], paste(sc$lhs, "~", sc$rhs)[sc$op == "~"])
cb_loadings <- setNames(sc$est.std[sc$op == "=~"], paste(sc$lhs, "=~", sc$rhs)[sc$op == "=~"])
cb_r2 <- lavInspect(cb, "r2")[c("VALUE", "SATISF", "INTENT")]

# 3. Regression on mean scores (the SPSS way, Post 14)
m <- data.frame(CONFIRM = rowMeans(x[, 1:4]), VALUE = rowMeans(x[, 5:8]), SATISF = rowMeans(x[, 9:12]),
                TRUST = rowMeans(x[, 13:16]), INTENT = rowMeans(x[, 17:20]))
z <- as.data.frame(scale(m))
r1 <- lm(VALUE ~ CONFIRM, z); r2 <- lm(SATISF ~ CONFIRM + VALUE, z); r3 <- lm(INTENT ~ CONFIRM + VALUE + SATISF + TRUST, z)
reg <- c(coef(r1)[2], coef(r2)[2:3], coef(r3)[2:5]); names(reg) <- paths
reg_r2 <- c(summary(r1)$r.squared, summary(r2)$r.squared, summary(r3)$r.squared)

r2_cs <- function(f) { r <- summarize(f)$Estimates$R2; r[c("VALUE", "SATISF", "INTENT")] }
tab <- data.frame(H = paste0("H", 1:7), path = paths, regression = reg, PLS = get_paths(pls)[paths],
                  PLSc = get_paths(plsc)[paths], CB_SEM = cb_paths[paths], row.names = NULL)
print(tab, digits = 3)
r2 <- data.frame(construct = c("VALUE", "SATISF", "INTENT"), regression = reg_r2, PLS = r2_cs(pls), PLSc = r2_cs(plsc),
                 CB_SEM = cb_r2, row.names = NULL)
print(r2, digits = 3)
ld <- data.frame(name = names(cb_loadings), PLS = get_loadings(pls)[names(cb_loadings)],
                 PLSc = get_loadings(plsc)[names(cb_loadings)], CB_SEM = cb_loadings, row.names = NULL)
print(ld, digits = 3)
cat("Mean loading: PLS", round(mean(ld$PLS), 3), " PLSc", round(mean(ld$PLSc), 3), " CB-SEM", round(mean(ld$CB_SEM), 3), "\n")
cat("CB-SEM fit:"); print(round(fitMeasures(cb, c("chisq", "df", "cfi", "rmsea", "srmr")), 3))
cat("SRMR PLS:", round(calculateSRMR(pls), 3), " SRMR PLSc:", round(calculateSRMR(plsc), 3), "\n")

# 4. Bootstrap of PLS-SEM (5000 samples as recommended by Hair et al., 2022), seed 2026
set.seed(2026)
bs <- resamplecSEMResults(pls, .R = 5000, .seed = 2026)
pb <- summarize(bs, .ci = "CI_percentile")$Estimates$Path_estimates
print(pb[, c("Name", "Estimate", "Std_err", "t_stat", "p_value")], digits = 3)
ci <- infer(bs, .quantity = "CI_percentile")$Path_estimates$CI_percentile
tab$PLS_se <- pb$Std_err[match(paths, pb$Name)]; tab$PLS_p <- pb$p_value[match(paths, pb$Name)]
tab$PLS_low <- ci["95%L", paths]; tab$PLS_up <- ci["95%U", paths]
pcb <- subset(parameterEstimates(cb), op == "~")
tab$CB_p <- pcb$pvalue[match(paths, paste(pcb$lhs, "~", pcb$rhs))]
print(tab, digits = 3)
write.csv(tab, "compare_paths.csv", row.names = FALSE)
write.csv(r2, "compare_r2.csv", row.names = FALSE)
write.csv(ld, "compare_loadings.csv", row.names = FALSE)
