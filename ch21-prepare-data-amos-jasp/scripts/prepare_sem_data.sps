* =====================================================================.
* Post 21. Prepare the data file for AMOS and JASP.
* Input:  marketplace_x_analysis.sav (267 valid responses, Posts 8 and 10).
* Output: marketplace_x_sem.sav          (267 responses, missing values kept, for FIML)
*         marketplace_x_sem_complete.sav (254 responses with all 20 items, for bootstrap)
*         marketplace_x_sem.csv          (plain-text copy for software that cannot read .sav)
* Run: pspp --syntax-encoding=UTF-8 prepare_sem_data.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* ---------------------------------------------------------------------.
* Step 1. Check the value range and the number of answers for each item.
* ---------------------------------------------------------------------.
DESCRIPTIVES VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4
    SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /STATISTICS=MEAN STDDEV MIN MAX.

* ---------------------------------------------------------------------.
* Step 2. Count the number of blank items for each respondent.
* ---------------------------------------------------------------------.
COUNT N_MISSING = CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4
    SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4 (MISSING).
VARIABLE LABELS N_MISSING 'Number of blank items (of the 20 model items)'.
FREQUENCIES N_MISSING.

* ---------------------------------------------------------------------.
* Step 3. Declare the items as quantitative (SCALE) variables.
* AMOS ignores this, but JASP does not: Ordinal variables are
* estimated with DWLS instead of ML (see Post 20).
* ---------------------------------------------------------------------.
VARIABLE LEVEL CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4
    SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4 (SCALE).

* ---------------------------------------------------------------------.
* Step 4. Save a lean file for AMOS: keep only the model items and the
* grouping variables. Drop the mean scores CONF, PV, SAT, TRU, RI so they
* do not clash with the names of the latent variables.
* ---------------------------------------------------------------------.
SAVE OUTFILE='../data/marketplace_x_sem.sav'
  /KEEP=ID GENDER OCCUP INCOME AGEGROUP
        CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4
        TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4 N_MISSING.
SAVE TRANSLATE OUTFILE='../data/marketplace_x_sem.csv' /TYPE=CSV /FIELDNAMES /REPLACE
  /KEEP=ID GENDER OCCUP INCOME AGEGROUP
        CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4
        TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4.

* ---------------------------------------------------------------------.
* Step 5. Also save a copy with only the respondents who answered all 20 items.
* ---------------------------------------------------------------------.
GET FILE='../data/marketplace_x_sem.sav'.
SELECT IF N_MISSING = 0.
SAVE OUTFILE='../data/marketplace_x_sem_complete.sav' /DROP=N_MISSING.
DESCRIPTIVES VARIABLES=N_MISSING /STATISTICS=MAX.
