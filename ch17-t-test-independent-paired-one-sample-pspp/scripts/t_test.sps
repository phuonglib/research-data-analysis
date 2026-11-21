* =====================================================================.
* Post 17. T-tests: independent samples, paired samples and one sample.
* Data: marketplace_x_analysis.sav. Run from the scripts/ folder: pspp --syntax-encoding=UTF-8 t_test.sps
* PSPP does not print the Cohen's d effect size; this file computes d with AGGREGATE.
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* ---------------------------------------------------------------------.
* Part 1. Independent Samples T-test: do men and women differ in repurchase intention?
* The gender group "Other" (code 3) is not one of the two groups compared, so it is excluded automatically.
* ---------------------------------------------------------------------.
EXAMINE VARIABLES=RI BY GENDER /PLOT=BOXPLOT /STATISTICS=NONE.
T-TEST /VARIABLES=RI SAT FREQ /GROUPS=GENDER(1,2) /MISSING=ANALYSIS /CRITERIA=CI(0.95).

* Cohen's d = mean difference / pooled standard deviation.
DATASET NAME MAIN.
DATASET COPY CALC_D.
DATASET ACTIVATE CALC_D.
SELECT IF ANY(GENDER, 1, 2) AND NOT MISSING(RI).
* AGGREGATE by group needs the data sorted by the grouping variable first.
SORT CASES BY GENDER.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /BREAK=GENDER /M_GROUP=MEAN(RI).
IF (GENDER = 1) RI_MALE = RI.
IF (GENDER = 2) RI_FEMALE = RI.
COMPUTE SQ_DEV = (RI - M_GROUP) ** 2.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /M_MALE=MEAN(RI_MALE) /M_FEMALE=MEAN(RI_FEMALE)
  /SS_WITHIN=SUM(SQ_DEV) /N_TOTAL=N(RI).
COMPUTE SD_POOLED = SQRT(SS_WITHIN / (N_TOTAL - 2)).
COMPUTE COHEN_D = (M_MALE - M_FEMALE) / SD_POOLED.
FORMATS M_MALE M_FEMALE SD_POOLED COHEN_D (F7.3).
TEMPORARY.
SELECT IF $CASENUM = 1.
LIST /VARIABLES=N_TOTAL M_MALE M_FEMALE SD_POOLED COHEN_D.
DATASET ACTIVATE MAIN.
DATASET CLOSE CALC_D.

* Nonparametric alternative: Mann-Whitney U test.
NPAR TESTS /M-W=RI BY GENDER(1 2).

* ---------------------------------------------------------------------.
* Part 2. Paired Samples T-test: do customers rate the benefit "helps me find good prices" (PV2)
* and "makes it easy to compare and choose products" (PV3) differently?
* ---------------------------------------------------------------------.
T-TEST /PAIRS=PV2 WITH PV3 (PAIRED) /CRITERIA=CI(0.95).
COMPUTE DIFF_PV = PV2 - PV3.
DESCRIPTIVES DIFF_PV /STATISTICS=MEAN STDDEV.
* Cohen's d for paired samples (d_z) = mean difference / standard deviation of the differences.
NPAR TESTS /WILCOXON=PV2 WITH PV3 (PAIRED).

* ---------------------------------------------------------------------.
* Part 3. One-Sample T-test: compare the mean with a given value.
* 3a. Against 3 (the Neutral level).  3b. Against 4 (marketplace X's target, "Agree").
* ---------------------------------------------------------------------.
T-TEST /TESTVAL=3 /VARIABLES=SAT RI /CRITERIA=CI(0.95).
T-TEST /TESTVAL=4 /VARIABLES=SAT RI /CRITERIA=CI(0.95).
