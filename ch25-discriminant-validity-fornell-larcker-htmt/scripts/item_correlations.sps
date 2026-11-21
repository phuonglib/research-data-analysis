* Post 25. Correlation matrix of the 20 items, to compute HTMT in Excel (htmt_fornell_larcker_template.xlsx).
* Run from the scripts folder:  pspp --syntax-encoding=UTF-8 item_correlations.sps
GET FILE='../data/marketplace_x_sem.sav'.
CORRELATIONS /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4
    TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=PAIRWISE /PRINT=NOSIG.
