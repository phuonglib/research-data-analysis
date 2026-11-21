* =====================================================================.
* Post 13. Pearson correlation between the composite variables.
* Data: marketplace_x_analysis.sav (267 responses; composite variables computed in Post 10).
* Run: pspp --syntax-encoding=UTF-8 correlation.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* Part 1. Pearson correlation matrix of the 5 composite variables (pairwise deletion, the default).
CORRELATIONS /VARIABLES=CONF PV SAT TRU RI /PRINT=TWOTAIL NOSIG /STATISTICS=DESCRIPTIVES.

* Part 2. Same matrix with listwise deletion: every coefficient uses the same set of responses.
CORRELATIONS /VARIABLES=CONF PV SAT TRU RI /MISSING=LISTWISE.

* Part 3. Correlation of the outcome RI with age and number of purchases.
CORRELATIONS /VARIABLES=RI AGE FREQ.
* Spearman rank correlation: less sensitive to outliers (response 99 has FREQ = 95).
* PSPP 2.0 has no NONPAR CORR command. Spearman is Pearson computed on ranks,
* so we rank the variables with RANK and run CORRELATIONS on the rank variables.
RANK VARIABLES=RI AGE FREQ (A) /RANK INTO R_RI R_AGE R_FREQ /TIES=MEAN.
CORRELATIONS /VARIABLES=R_RI R_AGE R_FREQ.
* Pearson correlation without response 99.
TEMPORARY.
SELECT IF ID <> 99.
CORRELATIONS /VARIABLES=RI FREQ.

* Part 4. Partial correlation: SAT and RI controlling for CONF and PV.
* PSPP 2.0 has no PARTIAL CORR command. Equivalent approach: take the residuals of SAT and of RI
* after regressing each on CONF and PV, then correlate the two sets of residuals.
* Use only responses with all 4 variables, on a copy of the data, so the main data are not affected.
DATASET NAME MAIN.
DATASET COPY PARTIALR.
DATASET ACTIVATE PARTIALR.
SELECT IF NMISS(SAT, RI, CONF, PV) = 0.
REGRESSION /VARIABLES=CONF PV /DEPENDENT=SAT /SAVE=RESID.
RENAME VARIABLES (RES1 = E_SAT).
REGRESSION /VARIABLES=CONF PV /DEPENDENT=RI /SAVE=RESID.
RENAME VARIABLES (RES1 = E_RI).
VARIABLE LABELS E_SAT 'SAT after removing the effect of CONF, PV' /E_RI 'RI after removing the effect of CONF, PV'.
CORRELATIONS /VARIABLES=E_SAT E_RI.
DATASET ACTIVATE MAIN.
DATASET CLOSE PARTIALR.

* Part 5. Scatter plots to check that the relationship is linear.
GRAPH /SCATTERPLOT(BIVAR)=SAT WITH RI.
GRAPH /SCATTERPLOT(BIVAR)=FREQ WITH RI.
