# =====================================================================
# Post 35. Discriminant validity of the Marketplace X model in PLS-SEM:
# HTMT (Henseler et al., 2015), Fornell-Larcker criterion, cross loadings,
# and bootstrap confidence intervals of HTMT (percentile, 5000 samples, seed 2026).
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33-34.
# Constructs are listed alphabetically, the same order as the SmartPLS report.
# Package: cSEM 0.7.1. Run:  LANG=C.UTF-8 Rscript discriminant_validity.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
blocks <- list(CONFIRM = paste0("CONF", 1:4), INTENT = paste0("RI", 1:4), SATISF = paste0("SAT", 1:4),
               TRUST = c("TRU1", "TRU2", "TRU3", "TRU4R"), VALUE = paste0("PV", 1:4))
cons <- names(blocks); items <- unlist(blocks, use.names = FALSE)
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
pls <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)

# 1. HTMT: mean heterotrait correlation / sqrt(product of the mean monotrait correlations)
htmt_mat <- function(dat) {
  R <- cor(dat)
  mono <- sapply(blocks, function(v) { r <- R[v, v]; mean(r[lower.tri(r)]) })
  H <- matrix(NA, 5, 5, dimnames = list(cons, cons))
  for (i in 2:5) for (j in 1:(i - 1)) {
    H[i, j] <- mean(R[blocks[[i]], blocks[[j]]]) / sqrt(mono[i] * mono[j])
  }
  H
}
H <- htmt_mat(x); print(round(H, 3))

# 2. Bootstrap confidence intervals of HTMT
set.seed(2026)
B <- 5000
pairs <- which(lower.tri(H), arr.ind = TRUE)
bs <- t(replicate(B, { h <- htmt_mat(x[sample(nrow(x), replace = TRUE), ]); h[lower.tri(h)] }))
pair_names <- paste(cons[pairs[, 1]], "<->", cons[pairs[, 2]])
htmt_table <- data.frame(pair = pair_names, HTMT = H[lower.tri(H)],
                         ci_lower = apply(bs, 2, quantile, 0.025), ci_upper = apply(bs, 2, quantile, 0.975),
                         q95 = apply(bs, 2, quantile, 0.95), row.names = NULL)
htmt_table <- htmt_table[order(-htmt_table$HTMT), ]
print(htmt_table, digits = 3, row.names = FALSE)

# 3. Fornell-Larcker: square root of AVE on the diagonal, latent variable correlations below it
a <- assess(pls, .quality_criterion = "ave")
LVcor <- cor(pls$Estimates$Construct_scores[, cons])
FL <- LVcor; diag(FL) <- sqrt(a$AVE[cons]); FL[upper.tri(FL)] <- NA
print(round(FL, 3))

# 4. Cross loadings: correlation of each item with the score of every latent variable
#    (items sorted alphabetically, as in the SmartPLS report)
items <- sort(items)
CL <- cor(x[, items], pls$Estimates$Construct_scores[, cons])
print(round(CL, 3))
own_con <- sapply(items, function(it) names(which(sapply(blocks, function(v) it %in% v))))
own <- sapply(seq_along(items), function(i) CL[i, own_con[i]])
other <- sapply(seq_along(items), function(i) max(CL[i, setdiff(cons, own_con[i])]))
cat("Smallest gap between own loading and largest cross loading:", round(min(own - other), 3),
    "(", items[which.min(own - other)], ")\n")

write.csv(round(H, 4), "htmt.csv")
write.csv(htmt_table, "htmt_bootstrap.csv", row.names = FALSE)
write.csv(round(FL, 4), "fornell_larcker.csv")
write.csv(round(CL, 4), "cross_loadings.csv")
