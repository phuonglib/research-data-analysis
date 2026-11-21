# =====================================================================
# Post 24. Composite reliability (CR) and average variance extracted (AVE).
# Computed from the standardized loadings of the CFA (Post 22), compared with
# Cronbach's alpha (Post 11) and with omega and AVE from semTools.
# Run: LANG=C.UTF-8 Rscript cr_ave.R
# =====================================================================
library(lavaan)
args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
d <- read.csv(file.path(here, "..", "data", "marketplace_x_sem.csv"))
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]
model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4'
fit <- cfa(model, data = x, missing = "ml")   # ML with FIML, N = 267
ss <- subset(standardizedSolution(fit), op == "=~")
write.csv(data.frame(lhs = ss$lhs, rhs = ss$rhs, std.all = ss$est.std), file.path(here, "loadings.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
alpha <- function(m) { k <- ncol(m); v <- cov(m); k / (k - 1) * (1 - sum(diag(v)) / sum(v)) }
res <- do.call(rbind, lapply(split(ss, ss$lhs), function(s) {
  l <- s$est.std; e <- 1 - l^2
  data.frame(factor = s$lhs[1], k = length(l), load_min = min(l), load_max = max(l),
             sum_load = sum(l), sum_load_sq = sum(l^2), sum_error = sum(e),
             CR = sum(l)^2 / (sum(l)^2 + sum(e)), AVE = mean(l^2),
             alpha = alpha(na.omit(x[, s$rhs])))   # complete cases per scale, as in Post 11
}))
res <- res[match(c("CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT"), res$factor), ]
res$sqrt_AVE <- sqrt(res$AVE)
lv <- lavInspect(fit, "cor.lv")
res$MSV <- sapply(res$factor, function(f) max(lv[f, colnames(lv) != f]^2))
print(res, digits = 3, row.names = FALSE)
write.csv(res, file.path(here, "cr_ave.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Check with semTools if installed (omega uses the unstandardized model, close to CR)
if (requireNamespace("semTools", quietly = TRUE)) {
  print(round(unlist(semTools::compRelSEM(fit)), 3))   # unlist: newer semTools returns a data frame
  print(round(unlist(semTools::AVE(fit)), 3))
}

# Illustration: how CR and AVE change when the item with the lowest loading is dropped
cat("\nDrop the item with the lowest loading:\n")
for (f in res$factor) {
  s <- ss[ss$lhs == f, ]; l <- s$est.std[-which.min(s$est.std)]; e <- 1 - l^2
  cat(sprintf("%-8s drop %-5s: CR %.3f -> %.3f, AVE %.3f -> %.3f\n", f, s$rhs[which.min(s$est.std)],
              res$CR[res$factor == f], sum(l)^2 / (sum(l)^2 + sum(e)), res$AVE[res$factor == f], mean(l^2)))
}
