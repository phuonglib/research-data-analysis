# =====================================================================
# Post 41. Moderation in PLS-SEM: does TRUST moderate the effect SATISF -> INTENT?
# Two-stage approach (Becker et al., 2018), the SmartPLS 4 default:
#   Stage 1: estimate the main-effects model and take the (standardized) latent variable scores.
#   Stage 2: add a single-item interaction term = SATISF score x TRUST score.
# Bootstrap with 5000 subsamples for stage 2 (approximation: stage 1 is not repeated in each subsample).
# Data: marketplace_x_sem.sav, casewise deletion on the 20 items (254 respondents), as in Posts 33 to 40.
# Package: cSEM 0.7.1. Run from this folder:  LANG=C.UTF-8 Rscript moderation.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- na.omit(d[, items]); cat("N =", nrow(x), "\n")
outer <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
inner <- '
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
'
f1 <- csem(x, paste(outer, inner, "\n  INTENT ~ CONFIRM + VALUE + SATISF + TRUST"),
           .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
sc <- f1$Estimates$Construct_scores
x$INTx <- sc[, "SATISF"] * sc[, "TRUST"]
f2 <- csem(x, paste(outer, "\n  INT =~ INTx", inner, "\n  INTENT ~ CONFIRM + VALUE + SATISF + TRUST + INT"),
           .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
P <- f2$Estimates$Path_estimates
r2_with <- f2$Estimates$R2["INTENT"]; r2_without <- f1$Estimates$R2["INTENT"]
cat("Path coefficients to INTENT:\n"); print(round(P["INTENT", ], 3))
cat("R2 of INTENT without / with the interaction:", round(r2_without, 3), round(r2_with, 3), "\n")
cat("f2 of the interaction:", round((r2_with - r2_without) / (1 - r2_with), 4), "\n")
set.seed(2026)
bs <- resamplecSEMResults(f2, .R = 5000, .seed = 2026)
s <- summarize(bs, .ci = "CI_percentile")$Estimates$Path_estimates
s <- s[grepl("^INTENT", s$Name), c("Name", "Estimate", "Std_err", "t_stat", "p_value", "CI_percentile.95%L", "CI_percentile.95%U")]
options(width = 200); print(s, digits = 3, row.names = FALSE)
# Simple slopes: effect of SATISF on INTENT when TRUST is at -1, 0 and +1 standard deviation
b_sat <- P["INTENT", "SATISF"]; b_int <- P["INTENT", "INT"]
# SmartPLS keeps the interaction term unstandardized (the product of scores): rescale the standardized coefficient
b_int_prod <- b_int / sd(x$INTx)
cat("SD of the score product:", round(sd(x$INTx), 3), " Interaction coefficient on the product scale:", round(b_int_prod, 3), "\n")
slopes <- data.frame(trust_level = c(-1, 0, 1), slope = b_sat + b_int_prod * c(-1, 0, 1))
print(round(slopes, 3))
write.csv(s, "moderation_bootstrap.csv", row.names = FALSE)
write.csv(slopes, "simple_slopes.csv", row.names = FALSE)
