* =====================================================================.
* Post 11. Scale reliability with Cronbach's Alpha.
* Data: marketplace_x_analysis.sav (267 responses, TRU4R created in Post 10).
* Run from the scripts/ folder: pspp --syntax-encoding=UTF-8 cronbach_alpha.sps
* =====================================================================.
GET FILE='../data/marketplace_x_analysis.sav'.

* Scale 1. Confirmation.
RELIABILITY /VARIABLES=CONF1 CONF2 CONF3 CONF4 /SCALE('Confirmation') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.
* Scale 2. Perceived value.
RELIABILITY /VARIABLES=PV1 PV2 PV3 PV4 /SCALE('Perceived value') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.
* Scale 3. Satisfaction.
RELIABILITY /VARIABLES=SAT1 SAT2 SAT3 SAT4 /SCALE('Satisfaction') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.
* Scale 4. Trust (uses the reverse-coded TRU4R).
RELIABILITY /VARIABLES=TRU1 TRU2 TRU3 TRU4R /SCALE('Trust') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.
* Scale 5. Repurchase intention.
RELIABILITY /VARIABLES=RI1 RI2 RI3 RI4 /SCALE('Repurchase intention') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.

* Illustration of the mistake: the Trust scale with TRU4 NOT reverse-coded.
RELIABILITY /VARIABLES=TRU1 TRU2 TRU3 TRU4 /SCALE('Trust - original TRU4 (WRONG)') ALL
  /MODEL=ALPHA /SUMMARY=TOTAL.

* Correlation matrix of the items within one scale (check the inter-item correlations).
CORRELATIONS /VARIABLES=TRU1 TRU2 TRU3 TRU4R.

* Split-half reliability, for reference.
RELIABILITY /VARIABLES=RI1 RI2 RI3 RI4 /SCALE('Repurchase intention') ALL /MODEL=SPLIT(2).
