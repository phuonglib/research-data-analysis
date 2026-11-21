# =====================================================================
# Post 20. The first model: one-factor CFA for the Satisfaction scale (SAT1-SAT4).
# Run:      LANG=C.UTF-8 Rscript first_model.R   (from the scripts folder)
# Needs:    R 4.x, package lavaan
# Same settings as AMOS: ML estimation, loading of SAT1 fixed to 1,
# missing data handled by FIML ("Estimate means and intercepts").
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_analysis.csv"))
items <- paste0("SAT", 1:4)
cat("Respondents missing at least one SAT item:", sum(!complete.cases(d[, items])), "\n")

# A latent variable must not share its name with a column in the data (the file already has
# a column SAT, the mean score), so the factor is called SATISF, as the naming rule in AMOS requires.
model <- 'SATISF =~ SAT1 + SAT2 + SAT3 + SAT4'
fit <- cfa(model, data = d[, items], estimator = "ML", missing = "ml")
summary(fit, fit.measures = TRUE, standardized = TRUE, rsquare = TRUE)
cat("\nDegrees of freedom: moments =", 4 * 5 / 2, "(without means); free parameters (without means) = 8\n")
pe <- parameterEstimates(fit, standardized = TRUE)
out <- subset(pe, op %in% c("=~", "~~"))[, c("lhs", "op", "rhs", "est", "se", "z", "pvalue", "std.all")]
print(out, digits = 3)
write.csv(out, file.path(here, "first_model_results.csv"), row.names = FALSE)
print(round(fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "rmsea.ci.lower",
                               "rmsea.ci.upper", "srmr", "npar")), 3))
print(subset(pe, op == "~1")[, c("lhs", "est")], digits = 3)
