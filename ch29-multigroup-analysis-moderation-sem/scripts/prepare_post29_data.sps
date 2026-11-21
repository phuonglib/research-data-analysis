* =====================================================================.
* Post 29. Prepare the data for multigroup analysis and moderation.
* Input:  marketplace_x_sem.sav (267 responses, Post 21).
* Output: marketplace_x_multigroup.sav          (262 male and female respondents; missing cells kept, for FIML)
*         marketplace_x_multigroup_complete.sav (250 male and female respondents with all items, for AMOS)
*         marketplace_x_product.sav             (267 responses + 4 product indicators SATxTRU1-SATxTRU4)
*         marketplace_x_product_complete.sav    (254 complete responses + 4 product indicators)
* Run: pspp --syntax-encoding=UTF-8 prepare_post29_data.sps
* =====================================================================.

* ---------------------------------------------------------------------.
* Part A. File for the multigroup analysis by gender.
* Drop the 5 respondents who chose "Other": the group is too small to
* estimate a separate model.
* ---------------------------------------------------------------------.
GET FILE='../data/marketplace_x_sem.sav'.
SELECT IF (GENDER = 1 OR GENDER = 2).
VALUE LABELS GENDER 1 'Male' 2 'Female'.
VARIABLE LEVEL GENDER (NOMINAL).
FREQUENCIES GENDER.
SAVE OUTFILE='../data/marketplace_x_multigroup.sav'.

COUNT N_MISS = CONF1 TO RI4 (MISSING).
SELECT IF (N_MISS = 0).
FREQUENCIES GENDER.
SAVE OUTFILE='../data/marketplace_x_multigroup_complete.sav' /DROP=N_MISS.

* ---------------------------------------------------------------------.
* Part B. Product indicators for the interaction SATISF x TRUST.
* Pairs in order: SAT1 x TRU1, SAT2 x TRU2, SAT3 x TRU3, SAT4 x TRU4R.
* Double-mean centering (Lin et al., 2010):
*   (1) subtract the mean of each original item,
*   (2) multiply the pairs,
*   (3) subtract the mean of each product.
* ---------------------------------------------------------------------.
GET FILE='../data/marketplace_x_sem.sav'.
AGGREGATE OUTFILE=* MODE=ADDVARIABLES
  /mSAT1=MEAN(SAT1) /mSAT2=MEAN(SAT2) /mSAT3=MEAN(SAT3) /mSAT4=MEAN(SAT4)
  /mTRU1=MEAN(TRU1) /mTRU2=MEAN(TRU2) /mTRU3=MEAN(TRU3) /mTRU4=MEAN(TRU4R).
COMPUTE t1 = (SAT1 - mSAT1) * (TRU1 - mTRU1).
COMPUTE t2 = (SAT2 - mSAT2) * (TRU2 - mTRU2).
COMPUTE t3 = (SAT3 - mSAT3) * (TRU3 - mTRU3).
COMPUTE t4 = (SAT4 - mSAT4) * (TRU4R - mTRU4).
AGGREGATE OUTFILE=* MODE=ADDVARIABLES
  /mt1=MEAN(t1) /mt2=MEAN(t2) /mt3=MEAN(t3) /mt4=MEAN(t4).
COMPUTE SATxTRU1 = t1 - mt1.
COMPUTE SATxTRU2 = t2 - mt2.
COMPUTE SATxTRU3 = t3 - mt3.
COMPUTE SATxTRU4 = t4 - mt4.
VARIABLE LABELS SATxTRU1 'Product SAT1 x TRU1 (double-centered)'
  SATxTRU2 'Product SAT2 x TRU2 (double-centered)'
  SATxTRU3 'Product SAT3 x TRU3 (double-centered)'
  SATxTRU4 'Product SAT4 x TRU4R (double-centered)'.
VARIABLE LEVEL SATxTRU1 TO SATxTRU4 (SCALE).
FORMATS SATxTRU1 TO SATxTRU4 (F8.4).
DESCRIPTIVES VARIABLES=SATxTRU1 TO SATxTRU4 /STATISTICS=MEAN STDDEV MIN MAX.
SAVE OUTFILE='../data/marketplace_x_product.sav'
  /DROP=mSAT1 TO mt4.
SAVE TRANSLATE OUTFILE='../data/marketplace_x_product.csv' /TYPE=CSV /FIELDNAMES /REPLACE
  /DROP=mSAT1 TO mt4.

COUNT N_MISS = CONF1 TO RI4 (MISSING).
SELECT IF (N_MISS = 0).
SAVE OUTFILE='../data/marketplace_x_product_complete.sav' /DROP=mSAT1 TO mt4 N_MISS.
