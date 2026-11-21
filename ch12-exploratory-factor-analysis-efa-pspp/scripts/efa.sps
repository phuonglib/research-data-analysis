* =====================================================================.
* Post 12. Exploratory factor analysis (EFA) of the 20 measurement items.
* Data: marketplace_x_analysis.sav (267 responses; TRU4 reverse-coded into TRU4R in Post 10).
* Run from the scripts/ folder: pspp --syntax-encoding=UTF-8 efa.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* Main run: principal axis factoring (PAF), Promax rotation, keep factors with eigenvalue > 1.
FACTOR
  /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=LISTWISE
  /PRINT=INITIAL KMO EXTRACTION ROTATION
  /PLOT=EIGEN
  /FORMAT=SORT BLANK(.30)
  /CRITERIA=MINEIGEN(1) ITERATE(100)
  /EXTRACTION=PAF
  /ROTATION=PROMAX(4).

* Comparison run: force 3 factors, as suggested by a PCA-based parallel analysis.
FACTOR
  /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=LISTWISE
  /PRINT=ROTATION
  /FORMAT=SORT BLANK(.30)
  /CRITERIA=FACTORS(3) ITERATE(100)
  /EXTRACTION=PAF
  /ROTATION=PROMAX(4).

* Comparison run: the common approach, PCA + Varimax.
FACTOR
  /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4 TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=LISTWISE
  /PRINT=EXTRACTION ROTATION
  /FORMAT=SORT BLANK(.30)
  /CRITERIA=MINEIGEN(1) ITERATE(100)
  /EXTRACTION=PC
  /ROTATION=VARIMAX.
