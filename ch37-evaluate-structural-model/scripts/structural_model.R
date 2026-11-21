# =====================================================================
# Post 37. Evaluating the structural model of the Marketplace X model (PLS-SEM):
# collinearity between latent variables (inner VIF), R-square, adjusted R-square, f-square.
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 35.
# Package: cSEM 0.7.1. Run from this folder:  LANG=C.UTF-8 Rscript structural_model.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- na.omit(d[, items]); n <- nrow(x); cat("N =", n, "\n")
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
LV <- as.data.frame(fit$Estimates$Construct_scores)
preds <- list(VALUE = "CONFIRM", SATISF = c("CONFIRM", "VALUE"), INTENT = c("CONFIRM", "VALUE", "SATISF", "TRUST"))

r2 <- function(y, xs) summary(lm(reformulate(xs, y), data = LV))$r.squared
# 1. VIF between the latent variables that predict the same endogenous construct
vif <- do.call(rbind, lapply(names(preds), function(y) {
  xs <- preds[[y]]
  data.frame(endogenous = y, predictor = xs, VIF = sapply(xs, function(v)
    if (length(xs) == 1) 1 else 1 / (1 - r2(v, setdiff(xs, v)))), row.names = NULL)
}))
# 2. R-square and adjusted R-square
R2 <- data.frame(construct = names(preds), R2 = sapply(names(preds), function(y) r2(y, preds[[y]])),
                 k = sapply(preds, length), row.names = NULL)
R2$R2_adjusted <- 1 - (1 - R2$R2) * (n - 1) / (n - R2$k - 1)
# 3. f-square = (R2 included - R2 excluded) / (1 - R2 included)
vif$R2_excluded <- mapply(function(y, v) if (length(preds[[y]]) == 1) 0 else r2(y, setdiff(preds[[y]], v)),
                          vif$endogenous, vif$predictor)
vif$f2 <- mapply(function(y, ex) { full <- r2(y, preds[[y]]); (full - ex) / (1 - full) },
                 vif$endogenous, vif$R2_excluded)
vif$path <- mapply(function(y, v) fit$Estimates$Path_estimates[y, v], vif$endogenous, vif$predictor)
print(R2, digits = 4); print(vif, digits = 4)
cat("Check against cSEM R-square:", round(summarize(fit)$Estimates$R2, 3), "\n")
write.csv(R2, "r2.csv", row.names = FALSE)
write.csv(vif, "vif_f2.csv", row.names = FALSE)
