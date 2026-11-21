# =====================================================================
# Post 33. Create the CSV file for SmartPLS from marketplace_x_sem.sav (267 respondents).
# Format change only: comma as delimiter, decimal point, first row holds the variable names,
# blank cells written as the code -99 (a value that cannot occur on the 1-5 Likert scale).
# No other value is changed. Run:  LANG=C.UTF-8 Rscript make_smartpls_csv.R
# =====================================================================
suppressMessages(library(foreign))
d <- read.spss("../data/marketplace_x_sem.sav", to.data.frame = TRUE, use.value.labels = FALSE)
d <- d[, !(names(d) %in% c("filter_$"))]
n_missing <- sum(is.na(d))
d[is.na(d)] <- -99
write.csv(d, "../data/marketplace_x_smartpls.csv", row.names = FALSE, quote = FALSE)
cat("Wrote", nrow(d), "rows,", ncol(d), "columns;", n_missing, "blank cells written as -99\n")
cat("Columns:", paste(names(d), collapse = ", "), "\n")
