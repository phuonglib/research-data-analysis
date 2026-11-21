# =====================================================================
# Post 36. Evaluating formative measurement models (SmartPLS 4 sample project
# "Example - Corporate reputation (primer)").
# Model "2 Extended model": ATTR, CSOR, PERF, QUAL formative -> COMP, LIKE (reflective) -> CUSA -> CUSL.
# Missing values: Mean replacement (the setting of the sample project), N = 344.
# Steps (Hair et al., 2022): (1) convergent validity by redundancy analysis, (2) collinearity (VIF),
# (3) significance and relevance of the outer weights (bootstrapping, 5000 subsamples, percentile).
# The data are read directly from the SmartPLS workspace; they belong to SmartPLS and are NOT
# included in this package. Install the sample project in SmartPLS first (Post 32, Section 4).
# If your SmartPLS workspace is in another folder, change `path` below.
# Package: cSEM 0.7.1. Run:  LANG=C.UTF-8 Rscript evaluate_formative.R
# =====================================================================
suppressMessages(library(cSEM))
path <- file.path(Sys.getenv("HOME"), "smartpls4_workspace", "Example - Corporate reputation (primer)", "Complete data.txt")
d <- read.table(path, sep = ";", header = TRUE, na.strings = c("", " "))
cat("N =", nrow(d), " Missing cells:", sum(is.na(d)), "\n")
x <- as.data.frame(lapply(d, function(v) { v[is.na(v)] <- mean(v, na.rm = TRUE); v }))  # Mean replacement

blocks <- list(ATTR = paste0("attr_", 1:3), CSOR = paste0("csor_", 1:5), PERF = paste0("perf_", 1:5),
               QUAL = paste0("qual_", 1:8))
model <- '
  ATTR <~ attr_1 + attr_2 + attr_3
  CSOR <~ csor_1 + csor_2 + csor_3 + csor_4 + csor_5
  PERF <~ perf_1 + perf_2 + perf_3 + perf_4 + perf_5
  QUAL <~ qual_1 + qual_2 + qual_3 + qual_4 + qual_5 + qual_6 + qual_7 + qual_8
  COMP =~ comp_1 + comp_2 + comp_3
  LIKE =~ like_1 + like_2 + like_3
  CUSA =~ cusa
  CUSL =~ cusl_1 + cusl_2 + cusl_3
  COMP ~ ATTR + CSOR + PERF + QUAL
  LIKE ~ ATTR + CSOR + PERF + QUAL
  CUSA ~ COMP + LIKE
  CUSL ~ COMP + LIKE + CUSA'
fit <- csem(x, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
cat("Converged:", unlist(verify(fit))[1] == FALSE, "\n")

# 1. Convergent validity: redundancy analysis (formative construct -> single-item global measure)
red <- sapply(names(blocks), function(k) {
  g <- paste0(tolower(k), "_global")
  m <- paste0(k, "_F <~ ", paste(blocks[[k]], collapse = " + "), "\n", k, "_G =~ ", g, "\n", k, "_G ~ ", k, "_F")
  r <- csem(x, m, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
  summarize(r)$Estimates$Path_estimates$Estimate
})
print(round(red, 3))

# 2. VIF of the formative indicators: 1 / (1 - R^2) when each indicator is regressed on the others in its block
res <- do.call(rbind, lapply(names(blocks), function(k) {
  v <- blocks[[k]]
  data.frame(construct = k, indicator = v, VIF = sapply(v, function(i)
    1 / (1 - summary(lm(reformulate(setdiff(v, i), i), data = x))$r.squared)), row.names = NULL)
}))

# 3. Outer weights, outer loadings and bootstrapping
W <- fit$Estimates$Weight_estimates; L <- fit$Estimates$Loading_estimates
res$weight <- mapply(function(k, i) W[k, i], res$construct, res$indicator)
res$loading <- mapply(function(k, i) L[k, i], res$construct, res$indicator)
set.seed(2026)
bs <- resamplecSEMResults(fit, .R = 5000, .seed = 2026)
sw <- summarize(bs)$Estimates$Weight_estimates
sl <- summarize(bs)$Estimates$Loading_estimates
nm_w <- paste(res$construct, "<~", res$indicator)
res$t_weight <- sw$t_stat[match(nm_w, sw$Name)]
res$p_weight <- sw$p_value[match(nm_w, sw$Name)]
nm_l <- paste(res$construct, "=~", res$indicator)
res$p_loading <- sl$p_value[match(nm_l, sl$Name)]
print(res, digits = 3, row.names = FALSE)

write.csv(data.frame(construct = names(red), path = red), "redundancy.csv", row.names = FALSE)
write.csv(res, "formative_vif_weights.csv", row.names = FALSE)
