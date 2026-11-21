* =====================================================================.
* Post 16. Dummy variables and moderator variables in regression.
* Data: marketplace_x_analysis.sav. Run: pspp --syntax-encoding=UTF-8 dummy_moderation.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* ---------------------------------------------------------------------.
* Part 1. Dummy variables for Occupation (4 groups -> 3 dummies, reference group: Student).
* ---------------------------------------------------------------------.
RECODE OCCUP (2=1) (1,3,4=0) (MISSING=SYSMIS) INTO D_OFFICE.
RECODE OCCUP (3=1) (1,2,4=0) (MISSING=SYSMIS) INTO D_SELFEMP.
RECODE OCCUP (4=1) (1,2,3=0) (MISSING=SYSMIS) INTO D_OTHER.
VARIABLE LABELS D_OFFICE 'Office worker (vs Student)'
  /D_SELFEMP 'Self-employed (vs Student)' /D_OTHER 'Other occupation (vs Student)'.
FORMATS D_OFFICE D_SELFEMP D_OTHER (F1.0).
* Check: each occupation group must map to exactly one 0/1 combination.
MEANS TABLES=D_OFFICE D_SELFEMP D_OTHER BY OCCUP /CELLS=MEAN COUNT.

* Dummy for Gender: Female = 1, Male = 0; the "Other" group (very small n) is set to missing.
RECODE GENDER (2=1) (1=0) (ELSE=SYSMIS) INTO D_FEMALE.
VARIABLE LABELS D_FEMALE 'Female (vs Male)'.
FORMATS D_FEMALE (F1.0).

* Mean RI by occupation, to compare with the dummy coefficients.
MEANS TABLES=RI BY OCCUP /CELLS=MEAN COUNT STDDEV.

* ---------------------------------------------------------------------.
* Part 2. Regression with dummy variables.
* ---------------------------------------------------------------------.
* 2a. Occupation dummies only: the constant = mean RI of the reference group.
REGRESSION /VARIABLES=D_OFFICE D_SELFEMP D_OTHER /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF R ANOVA.
* 2b. The dummy variable trap: all 4 dummies together with the constant.
RECODE OCCUP (1=1) (2,3,4=0) INTO D_STUDENT.
REGRESSION /VARIABLES=D_STUDENT D_OFFICE D_SELFEMP D_OTHER /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF R TOL.
* 2c. Model 2 of Post 14 plus the occupation and gender dummies as control variables.
DATASET NAME MAIN.
DATASET COPY COMPLETE.
DATASET ACTIVATE COMPLETE.
SELECT IF NMISS(CONF, PV, SAT, TRU, RI, D_OFFICE, D_FEMALE) = 0.
REGRESSION /VARIABLES=CONF PV SAT TRU /DEPENDENT=RI /METHOD=ENTER /STATISTICS=R ANOVA.
REGRESSION /VARIABLES=CONF PV SAT TRU D_OFFICE D_SELFEMP D_OTHER D_FEMALE /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF R ANOVA TOL.
DATASET ACTIVATE MAIN.
DATASET CLOSE COMPLETE.

* ---------------------------------------------------------------------.
* Part 3. Moderator: does Trust moderate the effect of Satisfaction on Repurchase intention?
* ---------------------------------------------------------------------.
* 3a. Product term without mean centering (to see the "spurious" multicollinearity).
COMPUTE SATxTRU_RAW = SAT * TRU.
* 3b. Mean centering: subtract the mean first, then multiply.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /M_SAT = MEAN(SAT) /M_TRU = MEAN(TRU) /M_CONF = MEAN(CONF) /M_PV = MEAN(PV)
  /SD_TRU = SD(TRU).
COMPUTE SAT_C = SAT - M_SAT.
COMPUTE TRU_C = TRU - M_TRU.
COMPUTE CONF_C = CONF - M_CONF.
COMPUTE PV_C = PV - M_PV.
COMPUTE SATxTRU = SAT_C * TRU_C.
VARIABLE LABELS SAT_C 'SAT (mean-centered)' /TRU_C 'TRU (mean-centered)' /SATxTRU 'SAT x TRU (mean-centered)'.
EXECUTE.

DATASET NAME MAIN.
DATASET COPY MODERATION.
DATASET ACTIVATE MODERATION.
SELECT IF NMISS(CONF, PV, SAT, TRU, RI) = 0.
* Block 1: the main variables. Block 2: add the product term.
REGRESSION /VARIABLES=CONF_C PV_C SAT_C TRU_C /DEPENDENT=RI /METHOD=ENTER /STATISTICS=R ANOVA.
REGRESSION /VARIABLES=CONF_C PV_C SAT_C TRU_C SATxTRU /DEPENDENT=RI /METHOD=ENTER
  /STATISTICS=COEFF CI(95) R ANOVA TOL.
* Comparison: the product term without mean centering.
REGRESSION /VARIABLES=CONF PV SAT TRU SATxTRU_RAW /DEPENDENT=RI /METHOD=ENTER /STATISTICS=COEFF TOL.

* 3c. Simple slopes: the effect of SAT when TRU is low (-1 SD), average, high (+1 SD).
* Technique: move the origin of TRU to the level of interest and rebuild the product term; the coefficient of SAT_C is then the simple slope.
COMPUTE TRU_LOW = TRU_C + SD_TRU.
COMPUTE TRU_HIGH = TRU_C - SD_TRU.
COMPUTE SATxTRU_LOW = SAT_C * TRU_LOW.
COMPUTE SATxTRU_HIGH = SAT_C * TRU_HIGH.
REGRESSION /VARIABLES=CONF_C PV_C SAT_C TRU_LOW SATxTRU_LOW /DEPENDENT=RI /METHOD=ENTER /STATISTICS=COEFF CI(95).
REGRESSION /VARIABLES=CONF_C PV_C SAT_C TRU_HIGH SATxTRU_HIGH /DEPENDENT=RI /METHOD=ENTER /STATISTICS=COEFF CI(95).
DATASET ACTIVATE MAIN.
DATASET CLOSE MODERATION.
