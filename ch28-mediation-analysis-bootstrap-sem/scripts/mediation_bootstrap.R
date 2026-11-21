# =====================================================================
# Post 28. Mediation analysis with bootstrapping.
# Specific indirect effect = product of the coefficients along a path.
#   1. Delta method (Sobel) on FIML (N = 267), for comparison
#   2. FIML (N = 267) + bootstrap 2000 samples, percentile CIs (as in JASP),
#      for unstandardized (B) and standardized (beta) estimates
#   3. Complete cases (N = 254) + bootstrap 2000 samples, percentile and
#      bias-corrected CIs (as in AMOS)
# Single-threaded on purpose (parallel = "no").
# Run:  LANG=C.UTF-8 Rscript mediation_bootstrap.R
# =====================================================================
library(lavaan)
set.seed(2026)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]; xc <- na.omit(x)
cat("N (FIML) =", nrow(x), "  complete cases =", nrow(xc), "\n")
model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  VALUE  ~ h1*CONFIRM
  SATISF ~ h2*CONFIRM + h3*VALUE
  INTENT ~ h4*CONFIRM + h5*VALUE + h6*SATISF + h7*TRUST
  CONFIRM ~~ TRUST
  # Specific indirect effects
  CONF_PV_RI     := h1*h5
  CONF_SAT_RI    := h2*h6
  CONF_PV_SAT_RI := h1*h3*h6
  PV_SAT_RI      := h3*h6
  CONF_PV_SAT    := h1*h3
  # Total indirect and total effects
  CONF_RI_indirect := h1*h5 + h2*h6 + h1*h3*h6
  CONF_RI_total    := h4 + h1*h5 + h2*h6 + h1*h3*h6
  PV_RI_total      := h5 + h3*h6
  # Compare two indirect paths
  diff_PV_SAT := h1*h5 - h2*h6'
keep <- function(p) p$op %in% c(":=", "~")

cat("== Delta method (Sobel), FIML ==\n")
f0 <- sem(model, data = x, missing = "ml")
sob <- parameterEstimates(f0)[keep(parameterEstimates(f0)), c("label", "est", "se", "z", "pvalue", "ci.lower", "ci.upper")]
print(sob, digits = 3, row.names = FALSE)
r2 <- lavInspect(f0, "r2")[c("VALUE", "SATISF", "INTENT")]
cat("R-square:", round(r2, 4), "\n")

# Standardized solution for every bootstrap draw (percentile CI of beta, as JASP prints with Standardized = All)
std_boot <- function(fit) {
  B <- lavInspect(fit, "boot")
  ss0 <- standardizedSolution(fit, se = FALSE)
  rows <- keep(ss0)
  t(apply(B, 1, function(th) {
    m <- lavaan:::lav_model_set_parameters(fit@Model, x = th)
    standardizedSolution(fit, se = FALSE, GLIST = m@GLIST, est = lav_model_get_parameters(m, type = "user"))$est.std[rows]
  }))
}
lav_model_get_parameters <- lavaan:::lav_model_get_parameters

cat("== FIML + bootstrap 2000 ==\n")
t0 <- Sys.time()
f1 <- sem(model, data = x, missing = "ml", se = "bootstrap", bootstrap = 2000, parallel = "no")
cat("time:", format(Sys.time() - t0), "\n")
p1 <- parameterEstimates(f1, boot.ci.type = "perc", standardized = TRUE); b1 <- p1[keep(p1), ]
sb <- std_boot(f1)
ss1 <- standardizedSolution(f1, se = FALSE); ss1 <- ss1[keep(ss1), ]
beta_low <- apply(sb, 2, quantile, 0.025, na.rm = TRUE); beta_up <- apply(sb, 2, quantile, 0.975, na.rm = TRUE)
beta_se <- apply(sb, 2, sd, na.rm = TRUE)
res1 <- data.frame(label = b1$label, B = b1$est, SE_boot = b1$se, p_boot = b1$pvalue, low = b1$ci.lower, up = b1$ci.upper,
                   beta = ss1$est.std, beta_se = beta_se, beta_p = 2 * pnorm(-abs(ss1$est.std / beta_se)),
                   beta_low = beta_low, beta_up = beta_up)
print(res1, digits = 3, row.names = FALSE)

cat("== Complete cases + bootstrap 2000 ==\n")
f2 <- sem(model, data = xc, se = "bootstrap", bootstrap = 2000, parallel = "no")
p2 <- parameterEstimates(f2, boot.ci.type = "perc"); p2 <- p2[keep(p2), ]
c2 <- parameterEstimates(f2, boot.ci.type = "bca.simple"); c2 <- c2[keep(c2), ]
res2 <- data.frame(label = p2$label, est = p2$est, perc_low = p2$ci.lower, perc_up = p2$ci.upper,
                   bc_low = c2$ci.lower, bc_up = c2$ci.upper)
print(res2, digits = 3, row.names = FALSE)

out <- data.frame(res1, sobel_se = sob$se, sobel_z = sob$z, sobel_p = sob$pvalue, sobel_low = sob$ci.lower, sobel_up = sob$ci.upper,
                  cc_B = res2$est, cc_perc_low = res2$perc_low, cc_perc_up = res2$perc_up, cc_bc_low = res2$bc_low, cc_bc_up = res2$bc_up)
write.csv(out, file.path(here, "mediation.csv"), row.names = FALSE)
cat("Written mediation.csv\n")
