* =====================================================================.
* Import Excel data (already coded as numbers) into PSPP/SPSS: four common situations.
* Run only ONE block, the one that matches your file (select the block, then Run > Selection).
* Edit the path in /FILE to match where the file is on your computer.
* /VARIABLES must list EVERY column in the file, in the same order.
* =====================================================================.

* Situation 1. Excel saved the file as "CSV UTF-8 (Comma delimited)": recommended.
GET DATA /TYPE=TXT /FILE='../data/excel_coded_utf8.csv' /ENCODING='UTF-8'
  /ARRANGEMENT=DELIMITED /DELCASE=LINE /FIRSTCASE=2 /DELIMITERS=','
  /VARIABLES=
    ID F4.0 SL1 F1.0 GENDER F1.0 AGE F3.0 OCCUP F1.0 INCOME F1.0 FREQ F3.0
    CONF1 F1.0 CONF2 F1.0 CONF3 F1.0 CONF4 F1.0 PV1 F1.0 PV2 F1.0 PV3 F1.0
    PV4 F1.0 SAT1 F1.0 SAT2 F1.0 AC1 F1.0 SAT3 F1.0 SAT4 F1.0 TRU1 F1.0
    TRU2 F1.0 TRU3 F1.0 TRU4 F1.0 RI1 F1.0 RI2 F1.0 RI3 F1.0 RI4 F1.0.
LIST /VARIABLES=ID SL1 GENDER AGE CONF1 RI4 /CASES=FROM 1 TO 3.

* Situation 2. Excel for Windows saved the file as plain "CSV (Comma delimited)":
* the file uses the computer's legacy code page (Windows-1252 on US and Western-European Windows),
* so declare that ENCODING, or accented letters such as the e in Cafe will come out wrong.
GET DATA /TYPE=TXT /FILE='../data/excel_coded_ansi.csv' /ENCODING='windows-1252'
  /ARRANGEMENT=DELIMITED /DELCASE=LINE /FIRSTCASE=2 /DELIMITERS=','
  /VARIABLES=
    ID F4.0 NOTE A20 SL1 F1.0 GENDER F1.0 AGE F3.0 OCCUP F1.0 INCOME F1.0 FREQ F3.0
    CONF1 F1.0 CONF2 F1.0 CONF3 F1.0 CONF4 F1.0 PV1 F1.0 PV2 F1.0 PV3 F1.0
    PV4 F1.0 SAT1 F1.0 SAT2 F1.0 AC1 F1.0 SAT3 F1.0 SAT4 F1.0 TRU1 F1.0
    TRU2 F1.0 TRU3 F1.0 TRU4 F1.0 RI1 F1.0 RI2 F1.0 RI3 F1.0 RI4 F1.0.
LIST /VARIABLES=ID NOTE SL1 GENDER /CASES=FROM 1 TO 3.

* Situation 3. The computer uses a decimal comma (many European and other locales):
* Excel separates the columns with semicolons.
GET DATA /TYPE=TXT /FILE='../data/excel_coded_semicolon.csv' /ENCODING='UTF-8'
  /ARRANGEMENT=DELIMITED /DELCASE=LINE /FIRSTCASE=2 /DELIMITERS=';'
  /VARIABLES=
    ID F4.0 SL1 F1.0 GENDER F1.0 AGE F3.0 OCCUP F1.0 INCOME F1.0 FREQ F3.0
    CONF1 F1.0 CONF2 F1.0 CONF3 F1.0 CONF4 F1.0 PV1 F1.0 PV2 F1.0 PV3 F1.0
    PV4 F1.0 SAT1 F1.0 SAT2 F1.0 AC1 F1.0 SAT3 F1.0 SAT4 F1.0 TRU1 F1.0
    TRU2 F1.0 TRU3 F1.0 TRU4 F1.0 RI1 F1.0 RI2 F1.0 RI3 F1.0 RI4 F1.0.
LIST /CASES=FROM 1 TO 3.

* Situation 4. Save the Excel workbook as ODS (LibreOffice format) and import it directly.
* READNAMES=ON: use the first row as variable names.
GET DATA /TYPE=ODS /FILE='../data/marketplace_x_raw.ods' /READNAMES=ON.
LIST /VARIABLES=ID SL1 GENDER AGE /CASES=FROM 1 TO 3.
