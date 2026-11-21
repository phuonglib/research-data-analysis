"""Sample files for Post 7 (importing data from Excel and Google Forms).
Builds the Post 7 practice files from the first 40 respondents of the shared raw data set.
  1. google_forms_responses.csv  simulated Google Forms export (UTF-8, headers are the questions, answers are text,
                                 grid questions look like "Question [Statement]")
  2. excel_coded_utf8.csv        the same answers already coded as numbers, saved as "CSV UTF-8"
  3. excel_coded_semicolon.csv   the same, with semicolons as separators (Excel in locales that use a decimal comma)
  4. excel_coded_ansi.csv        the same plus a text column with accented characters, saved as Windows-1252 ("CSV" in
                                 Western-European Windows), to show what happens with a wrong character encoding
Usage: python make_post07_files.py <output folder>
"""
import os
import sys
from datetime import datetime, timedelta

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "data", "marketplace_x_raw.csv")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "data", "post07")
os.makedirs(OUT, exist_ok=True)

df = pd.read_csv(SRC).head(40)
LIKERT = {1: "Strongly disagree", 2: "Disagree", 3: "Neutral", 4: "Agree", 5: "Strongly agree"}
GENDER = {1: "Male", 2: "Female", 3: "Other"}
OCCUP = {1: "Student", 2: "Office worker", 3: "Self-employed", 4: "Other"}
INCOME = {1: "Under $1,000", 2: "$1,000 to under $2,000", 3: "$2,000 to under $3,000", 4: "$3,000 or more"}
SL = {1: "Yes", 2: "No"}
STATEMENT = {
    "CONF1": "My shopping experience on Marketplace X was better than I expected",
    "CONF2": "The quality of the products I received was better than I expected",
    "CONF3": "The delivery service of Marketplace X was better than I expected",
    "CONF4": "Overall, most of my expectations of Marketplace X were met",
    "PV1": "Shopping on Marketplace X saves me time",
    "PV2": "Shopping on Marketplace X helps me find good prices",
    "PV3": "Marketplace X makes it easy to compare and choose products",
    "PV4": "Overall, Marketplace X is useful for my shopping needs",
    "SAT1": "I am satisfied with my purchases on Marketplace X",
    "SAT2": "Buying on Marketplace X was the right choice",
    "AC1": "To check your attention, please select Disagree for this item",
    "SAT3": "I feel pleased when shopping on Marketplace X",
    "SAT4": "Overall, I am satisfied with Marketplace X",
    "TRU1": "I believe Marketplace X is honest with its customers",
    "TRU2": "I believe Marketplace X protects my personal information",
    "TRU3": "I believe Marketplace X handles complaints fairly",
    "TRU4": "I worry that Marketplace X does not keep its promises",
    "RI1": "I intend to continue buying on Marketplace X",
    "RI2": "I will choose Marketplace X first for my next online purchase",
    "RI3": "I am likely to buy again on Marketplace X in the next 3 months",
    "RI4": "I will buy on Marketplace X more often",
}
GRID = "How much do you agree with the following statements?"

# 1. Google Forms export
t0 = datetime(2026, 10, 5, 8, 12, 0)
gf = pd.DataFrame()
gf["Timestamp"] = [(t0 + timedelta(minutes=37 * i + (i * 13) % 29)).strftime("%m/%d/%Y %H:%M:%S") for i in range(len(df))]
gf["In the past 6 months, have you bought anything on Marketplace X?"] = df["SL1"].map(SL)
gf["What is your gender?"] = df["GENDER"].map(GENDER)
gf["How old are you?"] = df["AGE"]
gf["What is your current occupation?"] = df["OCCUP"].map(OCCUP)
gf["What is your monthly income?"] = df["INCOME"].map(INCOME)
gf["In the past 6 months, how many times have you bought on Marketplace X?"] = df["FREQ"]
for c in STATEMENT:
    gf[f"{GRID} [{STATEMENT[c]}]"] = df[c].map(LIKERT)
gf.to_csv(os.path.join(OUT, "google_forms_responses.csv"), index=False, encoding="utf-8")

# 2-4. Excel files already coded as numbers
coded = df.copy()
coded.to_csv(os.path.join(OUT, "excel_coded_utf8.csv"), index=False, encoding="utf-8-sig")
coded.to_csv(os.path.join(OUT, "excel_coded_semicolon.csv"), index=False, sep=";", encoding="utf-8-sig")
ansi = coded.copy()
ansi.insert(1, "NOTE", ["Café owner" if i % 3 == 0 else "Résumé sent" for i in range(len(ansi))])
ansi.to_csv(os.path.join(OUT, "excel_coded_ansi.csv"), index=False, encoding="cp1252")
print("Created", len(df), "responses in", os.path.abspath(OUT))
