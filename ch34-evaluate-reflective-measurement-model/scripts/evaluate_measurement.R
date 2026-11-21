# =====================================================================
# Post 34. Evaluating the reflective measurement model of the Marketplace X model (PLS-SEM).
# Data: marketplace_x_sem.csv, casewise deletion on the 20 items (254 respondents), as in Post 33.
# Criteria: outer loadings, indicator reliability (squared loading), Cronbach's alpha,
#           rho_A (Dijkstra-Henseler), rho_c (composite reliability), AVE.
# Comparison: PLS-SEM (SmartPLS default), PLSc-SEM, and CB-SEM from Post 24.
# Package: cSEM 0.7.1. Run:  LANG=C.UTF-8 Rscript evaluate_measurement.R
# =====================================================================
suppressMessages(library(cSEM))
d <- read.csv("../data/marketplace_x_sem.csv")
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
cons <- c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT")

pls <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
plsc <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = TRUE)

# 1. Outer loadings and indicator reliability
ld <- summarize(pls)$Estimates$Loading_estimates
loadings <- data.frame(construct = sub(" =~.*", "", ld$Name), item = sub(".*=~ ", "", ld$Name),
                       loading = ld$Estimate, indicator_reliability = ld$Estimate^2)
loadings <- loadings[order(match(loadings$construct, cons), loadings$item), ]
print(loadings, digits = 3, row.names = FALSE)

# 2. Internal consistency reliability and AVE
a <- assess(pls, .quality_criterion = c("cronbachs_alpha", "reliability", "ave"))
# rho_A following Dijkstra & Henseler (2015): (w'w)^2 * w'(S - diag S)w / w'(ww' - diag ww')w,
# where w are the estimated weights (scaled so the composite has variance 1) and S is the item correlation matrix.
# (cSEM's assess() returns rho_A = 1 when .disattenuate = FALSE, so it is computed directly.)
S <- cor(x)
W <- pls$Estimates$Weight_estimates
rho_A <- sapply(cons, function(k) {
  v <- colnames(W)[W[k, ] != 0]; w <- W[k, v]; s <- S[v, v]  # matched by item name
  (sum(w^2))^2 * as.numeric(t(w) %*% (s - diag(diag(s))) %*% w) /
    as.numeric(t(w) %*% (w %*% t(w) - diag(w^2)) %*% w)
})
rel <- data.frame(construct = cons,
                  alpha = a$Reliability$Cronbachs_alpha[cons],
                  rho_A = rho_A[cons],
                  rho_c = a$Reliability$Joereskogs_rho[cons],
                  AVE = a$AVE[cons], row.names = NULL)
print(rel, digits = 3)

# Check with the formulas: rho_c = (sum L)^2 / [(sum L)^2 + sum(1 - L^2)], AVE = mean of L^2
by_hand <- do.call(rbind, lapply(split(loadings$loading, loadings$construct), function(L)
  c(rho_c = sum(L)^2 / (sum(L)^2 + sum(1 - L^2)), AVE = mean(L^2))))
print(round(by_hand[cons, ], 3))

# 3. AVE with PLSc (corrected) for comparison with CB-SEM in Post 24
ac <- assess(plsc, .quality_criterion = c("ave", "reliability"))
comparison <- data.frame(construct = cons, AVE_PLS = a$AVE[cons], AVE_PLSc = ac$AVE[cons],
                         rho_c_PLS = rel$rho_c, rho_c_PLSc = ac$Reliability$Joereskogs_rho[cons], row.names = NULL)
print(comparison, digits = 3)

# 4. Lowest loading and number of loadings below 0.708 (rule for 0.40 to 0.708)
cat("Lowest loading:", round(min(loadings$loading), 3), "(", loadings$item[which.min(loadings$loading)], ")\n")
cat("Loadings below 0.708:", sum(loadings$loading < 0.708), "\n")

write.csv(loadings, "outer_loadings.csv", row.names = FALSE)
write.csv(rel, "reliability_ave.csv", row.names = FALSE)
write.csv(comparison, "ave_pls_plsc.csv", row.names = FALSE)
