# =====================================================================
# Post 33. Cross-check numbers for the Marketplace X model drawn in SmartPLS 4.
# PLS-SEM, path weighting scheme, standardized results,
# two ways of handling missing values, as in SmartPLS:
#   (1) Casewise deletion: drop respondents with a blank cell (254 respondents)
#   (2) Mean replacement: replace a blank cell with the item mean (267 respondents)
# Package: cSEM 0.7.1. Run:  LANG=C.UTF-8 Rscript compare_pls.R
# =====================================================================
suppressMessages({ library(cSEM); library(foreign) })
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
items <- c(paste0("CONF", 1:4), paste0("PV", 1:4), paste0("SAT", 1:4), "TRU1", "TRU2", "TRU3", "TRU4R", paste0("RI", 1:4))
x <- d[, items]
cat("Respondents:", nrow(x), " Blank cells:", sum(is.na(x)), " Respondents with a blank cell:", sum(!complete.cases(x)), "\n")
cat("Largest share of blank cells in one item (%):", round(100 * max(colMeans(is.na(x))), 2), "\n")

model <- '
  CONFIRM =~ CONF1 + CONF2 + CONF3 + CONF4
  VALUE   =~ PV1 + PV2 + PV3 + PV4
  SATISF  =~ SAT1 + SAT2 + SAT3 + SAT4
  TRUST   =~ TRU1 + TRU2 + TRU3 + TRU4R
  INTENT  =~ RI1 + RI2 + RI3 + RI4
  VALUE   ~ CONFIRM
  SATISF  ~ CONFIRM + VALUE
  INTENT  ~ CONFIRM + VALUE + SATISF + TRUST'
paths <- c("VALUE ~ CONFIRM", "SATISF ~ CONFIRM", "SATISF ~ VALUE", "INTENT ~ CONFIRM",
           "INTENT ~ VALUE", "INTENT ~ SATISF", "INTENT ~ TRUST")

x_cw <- na.omit(x)
x_mr <- as.data.frame(lapply(x, function(v) { v[is.na(v)] <- mean(v, na.rm = TRUE); v }))

fit <- function(dat) csem(dat, model, .PLS_weight_scheme_inner = "path", .disattenuate = FALSE)
get <- function(f, k) { p <- summarize(f)$Estimates[[k]]; setNames(p$Estimate, p$Name) }
cw <- fit(x_cw); mr <- fit(x_mr)

path_tab <- data.frame(H = paste0("H", 1:7), path = paths,
                       casewise = get(cw, "Path_estimates")[paths], mean_replacement = get(mr, "Path_estimates")[paths],
                       row.names = NULL)
endo <- c("VALUE", "SATISF", "INTENT")
r2_tab <- data.frame(construct = endo,
                     casewise = summarize(cw)$Estimates$R2[endo],
                     mean_replacement = summarize(mr)$Estimates$R2[endo], row.names = NULL)
ld_cw <- get(cw, "Loading_estimates"); ld_mr <- get(mr, "Loading_estimates")
ld_tab <- data.frame(loading = names(ld_cw), casewise = ld_cw, mean_replacement = ld_mr[names(ld_cw)], row.names = NULL)
print(path_tab, digits = 3); print(r2_tab, digits = 3); print(ld_tab, digits = 3)
cat("Iterations: casewise", cw$Information$Weight_info$Number_iterations,
    " mean replacement", mr$Information$Weight_info$Number_iterations, "\n")
write.csv(path_tab, "path_comparison.csv", row.names = FALSE)
write.csv(r2_tab, "r2_comparison.csv", row.names = FALSE)
write.csv(ld_tab, "loadings_comparison.csv", row.names = FALSE)

# Check: SmartPLS casewise deletion drops respondents with blank cells in the model items (254),
# not in every column of the file (253, because ID 59 has a blank AGEGROUP but answered all 20 items).
x_all <- d[complete.cases(d), items]
ac <- fit(x_all)
cat("Dropping on every column:", nrow(x_all), "respondents; H1 =", round(get(ac, "Path_estimates")[paths[1]], 3),
    "; R2 INTENT =", round(summarize(ac)$Estimates$R2["INTENT"], 3), "\n")
cat("Dropping on the 20 items:", nrow(x_cw), "respondents; H1 =", round(path_tab$casewise[1], 3),
    "; R2 INTENT =", round(r2_tab$casewise[3], 3), "\n")
