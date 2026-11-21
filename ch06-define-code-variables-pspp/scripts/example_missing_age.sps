* Post 6: effect of declaring a user-missing code (AGE).
* Assume the first 12 respondents chose "Prefer not to say my age", coded 99.
* The case with age 230 (a data-entry error, handled in the data-cleaning post) is set aside first.
* Run from the scripts/ folder (the path below is relative to it).
GET FILE='../data/marketplace_x_raw.sav'.
SELECT IF (AGE < 100).
COMPUTE AGE2 = AGE.
IF (ID <= 12) AGE2 = 99.
* Before: code 99 is treated as a real age.
DESCRIPTIVES AGE2 /STATISTICS=MEAN STDDEV MIN MAX.
* After: code 99 declared as missing.
MISSING VALUES AGE2 (99).
DESCRIPTIVES AGE2 /STATISTICS=MEAN STDDEV MIN MAX.
