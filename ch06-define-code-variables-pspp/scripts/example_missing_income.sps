* Post 6: effect of declaring a user-missing code (INCOME).
* Assume the first 12 respondents chose "Prefer not to answer", coded 9.
* Run from the scripts/ folder (the path below is relative to it).
GET FILE='../data/marketplace_x_raw.sav'.
COMPUTE INCOME2 = INCOME.
IF (ID <= 12) INCOME2 = 9.
VALUE LABELS INCOME2 1 'Under $1,000' 2 '$1,000 to under $2,000' 3 '$2,000 to under $3,000' 4 '$3,000 or more' 9 'Prefer not to answer'.
* Before: code 9 is counted as an income level.
FREQUENCIES INCOME2 /STATISTICS=NONE.
DESCRIPTIVES INCOME2.
* After: code 9 declared as missing.
MISSING VALUES INCOME2 (9).
FREQUENCIES INCOME2 /STATISTICS=NONE.
DESCRIPTIVES INCOME2.
