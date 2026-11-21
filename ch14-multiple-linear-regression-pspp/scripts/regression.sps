* =====================================================================.
* Post 14. Multiple linear regression: testing hypotheses H1-H6.
* Data: marketplace_x_analysis.sav (267 responses; composite variables computed in Post 10).
* Run from the scripts/ folder: pspp --syntax-encoding=UTF-8 regression.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* Model 0 (H1). Simple regression: Confirmation -> Perceived value.
REGRESSION /VARIABLES=CONF /DEPENDENT=PV /METHOD=ENTER
  /STATISTICS=COEFF CI(95) R ANOVA.

* Model 1 (H2, H3). Confirmation and Perceived value -> Satisfaction.
REGRESSION /VARIABLES=CONF PV /DEPENDENT=SAT /METHOD=ENTER
  /STATISTICS=COEFF CI(95) R ANOVA TOL.

* Model 2 (H4, H5, H6). Four variables -> Repurchase intention.
* CONF is included to check whether CONF has a direct effect on RI beyond the path through SAT.
REGRESSION /VARIABLES=CONF PV SAT TRU /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF CI(95) R ANOVA TOL.

* Hierarchical regression: how much extra variance of RI does SAT explain?
* PSPP 2.0 does not support several /METHOD blocks in one REGRESSION command, so run two models
* on the SAME set of complete responses and compare R squared.
DATASET NAME MAIN.
DATASET COPY COMPLETE.
DATASET ACTIVATE COMPLETE.
SELECT IF NMISS(CONF, PV, SAT, TRU, RI) = 0.
REGRESSION /VARIABLES=CONF PV TRU /DEPENDENT=RI /METHOD=ENTER /STATISTICS=R ANOVA.
REGRESSION /VARIABLES=CONF PV TRU SAT /DEPENDENT=RI /METHOD=ENTER /STATISTICS=R ANOVA.
DATASET ACTIVATE MAIN.
DATASET CLOSE COMPLETE.
