* =====================================================================.
* Post 10. Recoding variables (RECODE) and computing composite variables (COMPUTE MEAN).
* Data: marketplace_x_clean.sav (267 responses, cleaned in Post 8).
* Run from the scripts folder: pspp --syntax-encoding=UTF-8 composite_variables.sps
* The result is saved as ../data/marketplace_x_analysis.sav (the shipped copy is overwritten with identical values); marketplace_x_clean.sav is not changed.
* =====================================================================.
GET FILE='../data/marketplace_x_clean.sav'.

* ---------------------------------------------------------------------.
* Part 1. Reverse-code the reverse-worded item TRU4 into a NEW variable TRU4R.
* ---------------------------------------------------------------------.
RECODE TRU4 (1=5) (2=4) (3=3) (4=2) (5=1) INTO TRU4R.
* Equivalent short form for a 1-5 scale: COMPUTE TRU4R = 6 - TRU4.
VARIABLE LABELS TRU4R 'TRU4 reverse-coded: I do NOT worry that marketplace X fails to keep its promises'.
VALUE LABELS TRU4R 1 'Strongly disagree' 2 'Disagree' 3 'Neutral' 4 'Agree' 5 'Strongly agree'.
FORMATS TRU4R (F1.0).
VARIABLE LEVEL TRU4R (ORDINAL).
EXECUTE.

* Check 1: the TRU4 x TRU4R crosstab must lie on the anti-diagonal.
CROSSTABS /TABLES=TRU4 BY TRU4R.
* Check 2: the correlations with the other items of the scale must turn from negative to positive.
CORRELATIONS /VARIABLES=TRU1 TRU2 TRU3 TRU4 TRU4R.

* ---------------------------------------------------------------------.
* Part 2. Three ways to compute the mean of a scale, and the number of responses lost.
* ---------------------------------------------------------------------.
COMPUTE CONF_ADD = (CONF1 + CONF2 + CONF3 + CONF4) / 4.
COMPUTE CONF_MEAN = MEAN(CONF1, CONF2, CONF3, CONF4).
COMPUTE CONF_MEAN3 = MEAN.3(CONF1, CONF2, CONF3, CONF4).
DESCRIPTIVES CONF_ADD CONF_MEAN CONF_MEAN3 /STATISTICS=MEAN STDDEV MIN MAX.

* ---------------------------------------------------------------------.
* Part 3. Two common mistakes: using TO, and forgetting the reverse-worded item.
* ---------------------------------------------------------------------.
* Mistake 1: SAT1 TO SAT4 goes by POSITION in the file, so it includes AC1, which sits between SAT2 and SAT3.
COMPUTE SAT_WRONG = MEAN(SAT1 TO SAT4).
COMPUTE SAT_RIGHT = MEAN(SAT1, SAT2, SAT3, SAT4).
* Mistake 2: using TRU4 before reverse-coding.
COMPUTE TRU_WRONG = MEAN(TRU1, TRU2, TRU3, TRU4).
COMPUTE TRU_RIGHT = MEAN(TRU1, TRU2, TRU3, TRU4R).
DESCRIPTIVES SAT_WRONG SAT_RIGHT TRU_WRONG TRU_RIGHT /STATISTICS=MEAN STDDEV MIN MAX.
CORRELATIONS /VARIABLES=SAT_WRONG SAT_RIGHT TRU_WRONG TRU_RIGHT RI1.

* ---------------------------------------------------------------------.
* Part 4. Composite variables for the 5 scales (provisional, until tested in Posts 11-12).
* MEAN.3: computed only when the respondent answered at least 3 of the 4 items.
* ---------------------------------------------------------------------.
COMPUTE CONF = MEAN.3(CONF1, CONF2, CONF3, CONF4).
COMPUTE PV = MEAN.3(PV1, PV2, PV3, PV4).
COMPUTE SAT = MEAN.3(SAT1, SAT2, SAT3, SAT4).
COMPUTE TRU = MEAN.3(TRU1, TRU2, TRU3, TRU4R).
COMPUTE RI = MEAN.3(RI1, RI2, RI3, RI4).
VARIABLE LABELS CONF 'Confirmation (mean of CONF1-CONF4)'
  /PV 'Perceived value (mean of PV1-PV4)'
  /SAT 'Satisfaction (mean of SAT1-SAT4)'
  /TRU 'Trust (mean of TRU1-TRU3, TRU4R)'
  /RI 'Repurchase intention (mean of RI1-RI4)'.
FORMATS CONF PV SAT TRU RI (F4.2).
VARIABLE LEVEL CONF PV SAT TRU RI (SCALE).
DESCRIPTIVES CONF PV SAT TRU RI /STATISTICS=MEAN STDDEV MIN MAX SKEWNESS KURTOSIS.

* ---------------------------------------------------------------------.
* Part 5. Group quantitative variables into ordinal variables (for description; the originals are kept).
* ---------------------------------------------------------------------.
RECODE AGE (LOWEST THRU 24=1) (25 THRU 34=2) (35 THRU 44=3) (45 THRU HIGHEST=4) INTO AGEGROUP.
RECODE FREQ (1 THRU 2=1) (3 THRU 5=2) (6 THRU 10=3) (11 THRU HIGHEST=4) INTO FREQGROUP.
VARIABLE LABELS AGEGROUP 'Age group' /FREQGROUP 'Purchase frequency group (past 6 months)'.
VALUE LABELS AGEGROUP 1 '18-24' 2 '25-34' 3 '35-44' 4 '45 and over'
  /FREQGROUP 1 '1-2 times' 2 '3-5 times' 3 '6-10 times' 4 'More than 10 times'.
FORMATS AGEGROUP FREQGROUP (F1.0).
VARIABLE LEVEL AGEGROUP FREQGROUP (ORDINAL).
FREQUENCIES AGEGROUP FREQGROUP /STATISTICS=NONE.
* Check the group boundaries: each group must have exactly the intended minimum and maximum age.
MEANS TABLES=AGE BY AGEGROUP /CELLS=MIN MAX COUNT.

* ---------------------------------------------------------------------.
* Part 6. Save the analysis file (drop the illustration variables).
* ---------------------------------------------------------------------.
SAVE OUTFILE='../data/marketplace_x_analysis.sav'
  /DROP=CONF_ADD CONF_MEAN CONF_MEAN3 SAT_WRONG SAT_RIGHT TRU_WRONG TRU_RIGHT.
