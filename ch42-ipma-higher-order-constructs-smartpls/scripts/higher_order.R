# =====================================================================
# Post 42 (part 2). Illustrative higher-order model: EVALUATION (Post-purchase evaluation) is a
# reflective-reflective higher-order construct of VALUE and SATISF, repeated indicators approach (Sarstedt et al., 2019).
#   EVALUATION is measured by all 8 items PV1-PV4, SAT1-SAT4 (repeated); EVALUATION -> VALUE, EVALUATION -> SATISF.
#   Structure: CONFIRM -> EVALUATION -> INTENT; CONFIRM -> INTENT; TRUST -> INTENT.
# This is a technical example, not the theoretical model of the series.
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents). Package: cSEM 0.7.1.
# Run from this folder:  LANG=C.UTF-8 Rscript higher_order.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- na.omit(d[, items]); cat("N =", nrow(x), "\n")
rep_items <- c(paste0("PV", 1:4), paste0("SAT", 1:4))
for (v in rep_items) x[[paste0(v, "_r")]] <- x[[v]]   # repeated copies of the 8 items for EVALUATION
model <- paste0('
  CONFIRM    =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE      =~ PV1 + PV2 + PV3 + PV4
  SATISF     =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST      =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT     =~ RI1 + RI2 + RI3 + RI4
  EVALUATION =~ ', paste(paste0(rep_items, "_r"), collapse = " + "), '
  VALUE      ~ EVALUATION
  SATISF     ~ EVALUATION
  EVALUATION ~ CONFIRM
  INTENT     ~ CONFIRM + EVALUATION + TRUST')
fit <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
cat("Converged:", unlist(verify(fit))[1] == FALSE, "\n")
P <- fit$Estimates$Path_estimates
cat("EVALUATION -> VALUE, SATISF (read as higher-order loadings):", round(P["VALUE", "EVALUATION"], 3), round(P["SATISF", "EVALUATION"], 3), "\n")
print(round(P[c("EVALUATION", "INTENT"), c("CONFIRM", "EVALUATION", "TRUST")], 3))
print(round(fit$Estimates$R2, 3))
# Reliability and convergent validity of the higher-order construct from the two higher-order "loadings"
l <- c(P["VALUE", "EVALUATION"], P["SATISF", "EVALUATION"])
cat("Higher-order AVE:", round(mean(l^2), 3), " higher-order rho_c:", round(sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), 3), "\n")
set.seed(2026)
bs <- resamplecSEMResults(fit, .R = 5000, .seed = 2026)
s <- summarize(bs, .ci = "CI_percentile")$Estimates$Path_estimates
cols <- c("Name", "Estimate", "Std_err", "t_stat", "p_value", "CI_percentile.95%L", "CI_percentile.95%U")
options(width = 200); print(s[, cols], digits = 3, row.names = FALSE)
write.csv(s[, cols], "higher_order_bootstrap.csv", row.names = FALSE)
