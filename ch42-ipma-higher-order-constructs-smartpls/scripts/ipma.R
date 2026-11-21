# =====================================================================
# Post 42 (part 1). IPMA (importance-performance map analysis) for the target construct INTENT
# (Ringle & Sarstedt, 2016).
#   Performance: latent variable scores on a 0-100 scale, using unstandardized outer weights rescaled to sum to 1.
#   Importance: total effect of each construct on INTENT. Ringle & Sarstedt (2016): unstandardized, on the 0-100 scores;
#   SmartPLS 4.1.2.1 reports standardized total effects. The script computes both.
# Items on a 1-5 scale: x0-100 = (x - 1) / (5 - 1) x 100. All items point in the same direction (TRU4R already reversed).
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 41.
# Package: cSEM 0.7.1 (function doIPMA) plus a hand calculation as a check.
# Run from this folder:  LANG=C.UTF-8 Rscript ipma.R
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
# Hand calculation
W <- fit$Estimates$Weight_estimates
x100 <- (x - 1) / 4 * 100
cons <- c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT")
# Unstandardized weights = standardized weights / item SD (SDs aligned with the column order of W)
Wu <- t(sapply(cons, function(k) { w <- W[k, ] / sapply(x, sd)[colnames(W)]; w[W[k, ] == 0] <- 0; w / sum(w) }))
LV <- as.matrix(x100) %*% t(Wu[, colnames(x)])
perf <- colMeans(LV)
b <- function(y, xs) coef(lm(reformulate(xs, y), data = as.data.frame(LV)))[xs]
bV <- b("VALUE", "CONFIRM"); bS <- b("SATISF", c("CONFIRM", "VALUE"))
bI <- b("INTENT", c("CONFIRM", "VALUE", "SATISF", "TRUST"))
imp <- c(CONFIRM = unname(bI["CONFIRM"] + bV * bI["VALUE"] + bS["CONFIRM"] * bI["SATISF"] + bV * bS["VALUE"] * bI["SATISF"]),
         VALUE = unname(bI["VALUE"] + bS["VALUE"] * bI["SATISF"]),
         SATISF = unname(bI["SATISF"]), TRUST = unname(bI["TRUST"]))
# Standardized total effects (what SmartPLS 4.1 reports as importance)
B <- fit$Estimates$Path_estimates; TE <- solve(diag(nrow(B)) - B) - diag(nrow(B)); dimnames(TE) <- dimnames(B)
res <- data.frame(construct = names(imp), importance_unstandardized = imp,
                  importance_standardized = TE["INTENT", names(imp)], performance = perf[names(imp)])
print(res, digits = 4, row.names = FALSE); cat("Performance INTENT:", round(perf["INTENT"], 3), "\n")
# Indicator level: importance = rescaled weight x construct importance; performance = mean on 0-100
ind <- do.call(rbind, lapply(names(imp), function(k) { v <- colnames(x)[Wu[k, colnames(x)] != 0]
  data.frame(construct = k, indicator = v, importance = Wu[k, v] * imp[k], performance = colMeans(x100[, v])) }))
ind$importance_standardized <- mapply(function(k, v) W[k, v] * TE["INTENT", k], ind$construct, ind$indicator)  # standardized weight x standardized total effect
print(ind, digits = 4, row.names = FALSE)
# Cross-check with cSEM's doIPMA
ip <- tryCatch(doIPMA(fit), error = function(e) { cat("doIPMA error:", conditionMessage(e), "\n"); NULL })
if (!is.null(ip)) print(ip)
write.csv(res, "ipma_constructs.csv", row.names = FALSE); write.csv(ind, "ipma_indicators.csv", row.names = FALSE)
