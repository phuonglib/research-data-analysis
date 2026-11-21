* =====================================================================.
* Post 30. Harman's single-factor test on the 20 model items.
* Factor analysis WITHOUT rotation; look at the percentage of variance of the first factor.
* Two runs: (1) let the software keep the factors with eigenvalue > 1,
* (2) force exactly 1 factor (the version often seen in theses).
* Run: pspp --syntax-encoding=UTF-8 harman.sps
* =====================================================================.
GET FILE='../data/marketplace_x_sem.sav'.

* (1) Principal components, no rotation, eigenvalue > 1.
FACTOR /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4
    TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=LISTWISE
  /EXTRACTION=PC
  /CRITERIA=MINEIGEN(1)
  /ROTATION=NOROTATE
  /PRINT=INITIAL EXTRACTION.

* (2) Principal axis factoring (PAF), 1 factor forced, no rotation.
FACTOR /VARIABLES=CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 SAT3 SAT4
    TRU1 TRU2 TRU3 TRU4R RI1 RI2 RI3 RI4
  /MISSING=LISTWISE
  /EXTRACTION=PAF
  /CRITERIA=FACTORS(1) ITERATE(100)
  /ROTATION=NOROTATE
  /PRINT=INITIAL EXTRACTION.
