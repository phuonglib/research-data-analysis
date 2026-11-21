* =====================================================================.
* Import a Google Forms export (CSV) into PSPP/SPSS and turn text answers into numeric codes.
* Run: open this file in a Syntax window and choose Run > All,
* or from the command line: pspp --syntax-encoding=UTF-8 import_google_forms.sps.
* Edit the path in /FILE to match where the file is on your computer.
* =====================================================================.

* Step 1. Import the data and give the variables short names (skip the header row with FIRSTCASE=2).
* Text answers go into temporary string variables with the suffix _S.
* GET DATA needs a format for every variable (A40 = string of up to 40 characters).
GET DATA
  /TYPE=TXT
  /FILE='../data/google_forms_responses.csv'
  /ENCODING='UTF-8'
  /ARRANGEMENT=DELIMITED
  /DELCASE=LINE
  /FIRSTCASE=2
  /DELIMITERS=','
  /QUALIFIER='"'
  /VARIABLES=
    TIMESTAMP A19 SL1_S A10 GENDER_S A10 AGE F3.0 OCCUP_S A30 INCOME_S A40 FREQ F3.0
    CONF1_S A30 CONF2_S A30 CONF3_S A30 CONF4_S A30 PV1_S A30 PV2_S A30 PV3_S A30
    PV4_S A30 SAT1_S A30 SAT2_S A30 AC1_S A30 SAT3_S A30 SAT4_S A30 TRU1_S A30
    TRU2_S A30 TRU3_S A30 TRU4_S A30 RI1_S A30 RI2_S A30 RI3_S A30 RI4_S A30.

* Step 2. Turn the text answers into numeric codes.
RECODE SL1_S ('Yes'=1) ('No'=2) INTO SL1.
RECODE GENDER_S ('Male'=1) ('Female'=2) ('Other'=3) INTO GENDER.
RECODE OCCUP_S ('Student'=1) ('Office worker'=2) ('Self-employed'=3) ('Other'=4) INTO OCCUP.
RECODE INCOME_S ('Under $1,000'=1) ('$1,000 to under $2,000'=2)
  ('$2,000 to under $3,000'=3) ('$3,000 or more'=4) INTO INCOME.

* The 21 Likert items share one rule: DO REPEAT avoids writing 21 commands.
DO REPEAT TXT = CONF1_S CONF2_S CONF3_S CONF4_S PV1_S PV2_S PV3_S PV4_S SAT1_S SAT2_S AC1_S
                SAT3_S SAT4_S TRU1_S TRU2_S TRU3_S TRU4_S RI1_S RI2_S RI3_S RI4_S
         /NUM = CONF1 CONF2 CONF3 CONF4 PV1 PV2 PV3 PV4 SAT1 SAT2 AC1
                SAT3 SAT4 TRU1 TRU2 TRU3 TRU4 RI1 RI2 RI3 RI4.
  RECODE TXT ('Strongly disagree'=1) ('Disagree'=2) ('Neutral'=3)
             ('Agree'=4) ('Strongly agree'=5) INTO NUM.
END REPEAT.
EXECUTE.

* Step 3. Check: every non-empty answer must have been turned into a number.
* A non-empty text cell whose numeric variable is missing means a spelling mismatch.
COUNT NOT_CODED = CONF1 TO RI4 (SYSMIS).
COUNT BLANK = CONF1_S TO RI4_S ('').
COMPUTE CODE_ERRORS = NOT_CODED - BLANK.
FREQUENCIES CODE_ERRORS /STATISTICS=NONE.

* Step 4. Keep the numeric variables in questionnaire order (drop the temporary text variables), add labels and save.
MATCH FILES /FILE=* /KEEP=TIMESTAMP SL1 GENDER AGE OCCUP INCOME FREQ CONF1 TO RI4.
VALUE LABELS
  SL1 1 'Yes' 2 'No'
  /GENDER 1 'Male' 2 'Female' 3 'Other'
  /OCCUP 1 'Student' 2 'Office worker' 3 'Self-employed' 4 'Other'
  /INCOME 1 'Under $1,000' 2 '$1,000 to under $2,000' 3 '$2,000 to under $3,000' 4 '$3,000 or more'
  /CONF1 TO RI4 1 'Strongly disagree' 2 'Disagree' 3 'Neutral' 4 'Agree' 5 'Strongly agree'.
FORMATS SL1 GENDER OCCUP INCOME CONF1 TO RI4 (F1.0).
VARIABLE LEVEL SL1 GENDER OCCUP (NOMINAL) /INCOME CONF1 TO RI4 (ORDINAL) /AGE FREQ (SCALE).
SAVE OUTFILE='../data/google_forms_coded.sav'.
LIST /VARIABLES=SL1 GENDER AGE OCCUP INCOME CONF1 CONF2 SAT1 RI1 /CASES=FROM 1 TO 5.
