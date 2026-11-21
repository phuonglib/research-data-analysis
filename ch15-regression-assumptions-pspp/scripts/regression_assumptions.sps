* =====================================================================.
* Post 15. Checking the assumptions of multiple linear regression (Model 2: RI).
* Data: marketplace_x_analysis.sav. Run from the scripts/ folder: pspp --syntax-encoding=UTF-8 regression_assumptions.sps
* PSPP 2.0 can only save predicted values (PRED) and residuals (RESID); the other statistics
* (standardized residuals, leverage, Cook's distance, Breusch-Pagan, Durbin-Watson) are computed with syntax.
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.
DATASET NAME MAIN.
DATASET COPY REG.
DATASET ACTIVATE REG.
SELECT IF NMISS(CONF, PV, SAT, TRU, RI) = 0.
EXECUTE.

* Step 1. Run the regression with collinearity statistics, save predicted values and residuals.
REGRESSION /VARIABLES=CONF PV SAT TRU /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF R ANOVA TOL /SAVE=PRED RESID.
RENAME VARIABLES (PRED1 = PREDICTED) (RES1 = RESIDUAL).

* Step 2. Standardize the predicted values and the residuals.
* Standardized residual = residual / standard error of the estimate (square root of MSE, df N - k - 1).
COMPUTE RES_SQ = RESIDUAL ** 2.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /SSE = SUM(RES_SQ) /N_REG = N(RESIDUAL)
  /M_PRED = MEAN(PREDICTED) /SD_PRED = SD(PREDICTED).
COMPUTE ZRESID = RESIDUAL / SQRT(SSE / (N_REG - 5)).
COMPUTE ZPRED = (PREDICTED - M_PRED) / SD_PRED.
VARIABLE LABELS ZRESID 'Standardized residual' /ZPRED 'Standardized predicted value'.
EXECUTE.

* Step 2b. Linearity: Ramsey's RESET test.
* Add the squared predicted value to the model; if its coefficient is significant, the relationship may not be linear.
COMPUTE PRED_SQ = PREDICTED ** 2.
REGRESSION /VARIABLES=CONF PV SAT TRU PRED_SQ /DEPENDENT=RI /METHOD=ENTER /STATISTICS=COEFF.

* Step 3. Normality of the residuals: histogram, Q-Q plot, Shapiro-Wilk test.
EXAMINE VARIABLES=ZRESID /PLOT=HISTOGRAM NPPLOT /STATISTICS=DESCRIPTIVES EXTREME(5) /ID=ID.

* Step 4. Constant error variance: scatter plot of ZRESID against ZPRED.
GRAPH /SCATTERPLOT(BIVAR)=ZPRED WITH ZRESID.

* Breusch-Pagan test (Koenker version): regress the squared residuals on the independent variables.
* LM statistic = N x R squared of the auxiliary regression, chi-square distributed with 4 degrees of freedom.
REGRESSION /VARIABLES=CONF PV SAT TRU /DEPENDENT=RES_SQ /METHOD=ENTER /STATISTICS=R ANOVA.

* Step 5. Independence of the residuals: Durbin-Watson statistic (depends on the order of responses in the file).
SORT CASES BY ID.
COMPUTE DIFF_SQ = (RESIDUAL - LAG(RESIDUAL)) ** 2.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /SUM_DIFF_SQ = SUM(DIFF_SQ).
COMPUTE DW = SUM_DIFF_SQ / SSE.
FORMATS DW (F6.3).
TEMPORARY.
SELECT IF $CASENUM = 1.
LIST /VARIABLES=DW SSE N_REG.

* Step 6. Influential cases: leverage and Cook's distance, computed with MATRIX.
MATRIX.
GET X /VARIABLES=CONF PV SAT TRU.
GET E /VARIABLES=RESIDUAL.
GET IDS /VARIABLES=ID.
COMPUTE N = NROW(X).
COMPUTE X1 = {MAKE(N, 1, 1), X}.
COMPUTE P = NCOL(X1).
COMPUTE H = DIAG(X1 * INV(T(X1) * X1) * T(X1)).
COMPUTE MSE = CSSQ(E) / (N - P).
COMPUTE COOK = (E &** 2 / (P * MSE)) &* (H &/ (1 - H) &** 2).
COMPUTE SRESID = E &/ SQRT(MSE * (1 - H)).
SAVE {IDS, H, COOK, SRESID} /OUTFILE='../data/influence.sav' /VARIABLES=ID LEVERAGE COOK SRESID.
END MATRIX.
SORT CASES BY ID.
MATCH FILES /FILE=* /FILE='../data/influence.sav' /BY ID.
FORMATS ID (F4.0) LEVERAGE COOK SRESID (F7.3).
* Cut-offs: Cook > 4/N; leverage > 2(k+1)/N; studentized residual with absolute value > 3.
COMPUTE HIGH_COOK = (COOK > 4 / N_REG).
COMPUTE HIGH_LEV = (LEVERAGE > 2 * 5 / N_REG).
COMPUTE HIGH_SRES = (ABS(SRESID) > 3).
FREQUENCIES HIGH_COOK HIGH_LEV HIGH_SRES /STATISTICS=NONE.
DESCRIPTIVES COOK LEVERAGE SRESID /STATISTICS=MEAN MIN MAX.
SORT CASES BY COOK (D).
LIST /VARIABLES=ID RI PREDICTED RESIDUAL SRESID LEVERAGE COOK /CASES=FROM 1 TO 6.
SORT CASES BY ID.

* Step 7. Sensitivity analysis: rerun the regression without the responses with Cook > 4/N.
TEMPORARY.
SELECT IF COOK <= 4 / N_REG.
REGRESSION /VARIABLES=CONF PV SAT TRU /DEPENDENT=RI /METHOD=ENTER /STATISTICS=COEFF R ANOVA.

SAVE OUTFILE='../data/regression_residuals.sav'
  /KEEP=ID RI PREDICTED RESIDUAL ZPRED ZRESID SRESID LEVERAGE COOK.
DATASET ACTIVATE MAIN.
DATASET CLOSE REG.
