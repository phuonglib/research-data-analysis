* =====================================================================.
* Post 8. Data cleaning: remove invalid responses, fix data entry errors,
* handle missing values and detect outliers.
* Run: open this file in a Syntax window and choose Run > All,
* or from the command line: pspp --syntax-encoding=UTF-8 data_cleaning.sps.
* The original file is NOT overwritten: the result is saved as marketplace_x_clean.sav.
* =====================================================================.

GET FILE='../data/marketplace_x_raw.sav'.

* ---------------------------------------------------------------------.
* Step 1. Quick check: frequencies of the control items, value range of every variable.
* ---------------------------------------------------------------------.
FREQUENCIES SL1 AC1 /STATISTICS=NONE.
DESCRIPTIVES AGE FREQ CONF1 TO RI4 /STATISTICS=MEAN STDDEV MIN MAX.

* ---------------------------------------------------------------------.
* Step 2. Flag invalid responses (nothing deleted yet, only 0/1 flag variables).
* ---------------------------------------------------------------------.
* Standard deviation of the 20 Likert items within one response (AC1 not included).
COMPUTE RESP_SD = SD(CONF1 TO SAT2, SAT3 TO RI4).
COMPUTE ERR_SCREEN = (SL1 = 2).
COMPUTE ERR_ATTENTION = (AC1 <> 2).
COMPUTE ERR_STRAIGHT = (RESP_SD = 0).
COMPUTE EXCLUDE = MAX(ERR_SCREEN, ERR_ATTENTION, ERR_STRAIGHT).
FORMATS RESP_SD (F4.2) ERR_SCREEN ERR_ATTENTION ERR_STRAIGHT EXCLUDE (F1.0).
VALUE LABELS ERR_SCREEN ERR_ATTENTION ERR_STRAIGHT EXCLUDE 0 'No' 1 'Yes'.
FREQUENCIES ERR_SCREEN ERR_ATTENTION ERR_STRAIGHT EXCLUDE /STATISTICS=NONE.
CROSSTABS /TABLES=ERR_ATTENTION BY ERR_STRAIGHT.

* Look at the straight-lining responses before removing them.
TEMPORARY.
SELECT IF ERR_STRAIGHT = 1.
LIST /VARIABLES=ID AC1 CONF1 PV1 SAT1 TRU1 TRU4 RI1 RESP_SD.

* ---------------------------------------------------------------------.
* Step 3. Remove invalid responses.
* ---------------------------------------------------------------------.
SELECT IF EXCLUDE = 0.
EXECUTE.

* ---------------------------------------------------------------------.
* Step 4. Fix data entry errors outside the valid range.
* There are no paper questionnaires to check against, so wrong values are set to missing.
* ---------------------------------------------------------------------.
COUNT OUT_RANGE = CONF1 TO SAT2 SAT3 TO RI4 (LOWEST THRU 0, 6 THRU HIGHEST).
TEMPORARY.
SELECT IF AGE > 60 OR AGE < 18 OR OUT_RANGE > 0.
LIST /VARIABLES=ID AGE OUT_RANGE CONF1 TO SAT2.
IF (AGE > 60 OR AGE < 18) AGE = $SYSMIS.
RECODE CONF1 TO SAT2 SAT3 TO RI4 (6 THRU HIGHEST = SYSMIS) (LOWEST THRU 0 = SYSMIS).
EXECUTE.

* ---------------------------------------------------------------------.
* Step 5. Assess missing values.
* ---------------------------------------------------------------------.
COMPUTE N_BLANK = NMISS(CONF1 TO SAT2, SAT3 TO RI4).
FORMATS N_BLANK (F2.0).
FREQUENCIES N_BLANK /STATISTICS=NONE.
DESCRIPTIVES CONF1 TO SAT2 SAT3 TO RI4 /STATISTICS=MEAN MIN MAX.

* Quick check: do responses with blanks differ from complete responses on other variables?
COMPUTE HAS_BLANK = (N_BLANK > 0).
VALUE LABELS HAS_BLANK 0 'Complete' 1 'Has blanks'.
T-TEST GROUPS=HAS_BLANK(0 1) /VARIABLES=AGE FREQ.
CROSSTABS /TABLES=GENDER BY HAS_BLANK /STATISTICS=CHISQ.

* ---------------------------------------------------------------------.
* Step 6. Univariate outliers: z-scores and box plots.
* DESCRIPTIVES /SAVE creates the variables ZAGE, ZFREQ, ZCONF1... in the data.
* ---------------------------------------------------------------------.
DESCRIPTIVES AGE FREQ CONF1 TO SAT2 SAT3 TO RI4 /SAVE /STATISTICS=MEAN STDDEV MIN MAX.
COMPUTE Z_OUTLIER = ANY(1, ABS(ZAGE) > 3.29, ABS(ZFREQ) > 3.29).
TEMPORARY.
SELECT IF Z_OUTLIER = 1.
LIST /VARIABLES=ID AGE ZAGE FREQ ZFREQ.
EXAMINE VARIABLES=FREQ AGE /PLOT=BOXPLOT /STATISTICS=EXTREME(5).

* ---------------------------------------------------------------------.
* Step 7. Multivariate outliers: Mahalanobis distance on the 20 Likert items.
* Cut-off: chi-square with df = 20, p < .001 is 45.31.
* ---------------------------------------------------------------------.
DATASET NAME CLEAN.
DATASET COPY COMPLETE.
DATASET ACTIVATE COMPLETE.
SELECT IF N_BLANK = 0.
MATCH FILES /FILE=* /KEEP=ID CONF1 TO SAT2 SAT3 TO RI4.
MATRIX.
GET X /VARIABLES=CONF1 TO RI4.
GET IDS /VARIABLES=ID.
COMPUTE N = NROW(X).
COMPUTE XC = X - MAKE(N, 1, 1) * CSUM(X) / N.
COMPUTE S = T(XC) * XC / (N - 1).
COMPUTE D2 = RSUM((XC * INV(S)) &* XC).
SAVE {IDS, D2} /OUTFILE=* /VARIABLES=ID MAHAL.
END MATRIX.
COMPUTE P_MAHAL = SIG.CHISQ(MAHAL, 20).
FORMATS ID (F4.0) MAHAL (F6.2) P_MAHAL (F6.4).
SORT CASES BY MAHAL (D).
LIST /CASES=FROM 1 TO 5.
COMPUTE MV_OUTLIER = (P_MAHAL < .001).
FREQUENCIES MV_OUTLIER /STATISTICS=NONE.
SORT CASES BY ID.
DATASET NAME MAHALANOBIS.

* Merge the Mahalanobis distance into the main data by ID.
DATASET ACTIVATE CLEAN.
SORT CASES BY ID.
MATCH FILES /FILE=* /TABLE=MAHALANOBIS /BY ID.
DATASET CLOSE MAHALANOBIS.

* ---------------------------------------------------------------------.
* Step 8. Save the clean data set (drop the intermediate flag variables).
* ---------------------------------------------------------------------.
SAVE OUTFILE='../data/marketplace_x_clean.sav'
  /DROP=OUT_RANGE ERR_SCREEN ERR_ATTENTION ERR_STRAIGHT EXCLUDE HAS_BLANK Z_OUTLIER ZAGE ZFREQ ZCONF1 TO ZRI4.
DESCRIPTIVES AGE FREQ CONF1 TO SAT2 SAT3 TO RI4 /STATISTICS=MEAN STDDEV MIN MAX.
