* =====================================================================.
* Post 18. One-way analysis of variance (ANOVA) and post-hoc tests.
* Data: marketplace_x_analysis.sav. Run from the scripts folder: pspp --syntax-encoding=UTF-8 anova.sps
* PSPP (2.0.0 and 2.1.2) has no Welch ANOVA and does not print eta squared;
* Part 3 computes both with AGGREGATE.
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.
DATASET NAME MAIN.

* ---------------------------------------------------------------------.
* Part 1. Check the assumptions: box plot of RI by income group.
* ---------------------------------------------------------------------.
EXAMINE VARIABLES=RI BY INCOME /PLOT=BOXPLOT /STATISTICS=NONE.

* ---------------------------------------------------------------------.
* Part 2. One-way ANOVA: RI by income, with Levene's test, post-hoc tests
* and a linear trend contrast (-3 -1 1 3).
* ---------------------------------------------------------------------.
ONEWAY /VARIABLES=RI BY INCOME
  /STATISTICS=DESCRIPTIVES HOMOGENEITY
  /POSTHOC=TUKEY BONFERRONI GH
  /CONTRAST=-3 -1 1 3.

* ---------------------------------------------------------------------.
* Part 3. Welch ANOVA, eta squared and omega squared.
* ---------------------------------------------------------------------.
DATASET COPY CALC_W.
DATASET ACTIVATE CALC_W.
SELECT IF NOT MISSING(RI) AND NOT MISSING(INCOME).
SORT CASES BY INCOME.
* Aggregate the data into one row per group.
AGGREGATE /OUTFILE=* /BREAK=INCOME /N_J=N(RI) /M_J=MEAN(RI) /SD_J=SD(RI).
COMPUTE W_J = N_J / SD_J ** 2.
COMPUTE WM_J = W_J * M_J.
COMPUTE NM_J = N_J * M_J.
COMPUTE SSW_J = (N_J - 1) * SD_J ** 2.
COMPUTE ONE = 1.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /BREAK=ONE
  /W=SUM(W_J) /SUM_WM=SUM(WM_J) /N=SUM(N_J) /SUM_NM=SUM(NM_J) /SSW=SUM(SSW_J) /K=N(N_J).
COMPUTE M_W = SUM_WM / W.
COMPUTE M_GRAND = SUM_NM / N.
COMPUTE A_J = W_J * (M_J - M_W) ** 2.
COMPUTE H_J = (1 - W_J / W) ** 2 / (N_J - 1).
COMPUTE SSB_J = N_J * (M_J - M_GRAND) ** 2.
AGGREGATE /OUTFILE=* MODE=ADDVARIABLES /BREAK=ONE
  /SUM_A=SUM(A_J) /SUM_H=SUM(H_J) /SSB=SUM(SSB_J).
COMPUTE F_WELCH = (SUM_A / (K - 1)) / (1 + 2 * (K - 2) / (K ** 2 - 1) * SUM_H).
COMPUTE DF1 = K - 1.
COMPUTE DF2 = (K ** 2 - 1) / (3 * SUM_H).
COMPUTE P_WELCH = 1 - CDF.F(F_WELCH, DF1, DF2).
COMPUTE MSW = SSW / (N - K).
COMPUTE ETA2 = SSB / (SSB + SSW).
COMPUTE OMEGA2 = (SSB - (K - 1) * MSW) / (SSB + SSW + MSW).
FORMATS F_WELCH DF2 (F8.2) ETA2 OMEGA2 (F8.3) P_WELCH (F8.4) DF1 (F3.0).
VARIABLE LABELS F_WELCH 'Welch F' DF1 'df1' DF2 'df2' P_WELCH 'Sig.' ETA2 'Eta squared' OMEGA2 'Omega squared'.
TEMPORARY.
SELECT IF $CASENUM = 1.
LIST /VARIABLES=F_WELCH DF1 DF2 P_WELCH ETA2 OMEGA2.
DATASET ACTIVATE MAIN.
DATASET CLOSE CALC_W.

* ---------------------------------------------------------------------.
* Part 4. Nonparametric alternative: Kruskal-Wallis test.
* ---------------------------------------------------------------------.
NPAR TESTS /K-W=RI BY INCOME(1, 4).

* ---------------------------------------------------------------------.
* Part 5. A non-significant example: RI by occupation (compare with Post 16).
* ---------------------------------------------------------------------.
ONEWAY /VARIABLES=RI BY OCCUP /STATISTICS=DESCRIPTIVES HOMOGENEITY.
