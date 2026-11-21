"""
Post 9: write ../data/marketplace_x_clean.csv from ../data/marketplace_x_clean.sav.
Same result as descriptive_statistics_export.sps (SAVE TRANSLATE /TYPE=CSV /FIELDNAMES): numeric codes,
variable names in the first row, missing values as empty cells. make_figures.py reads this CSV for Figure 7.
Run:  python export_csv.py
Needs: pyreadstat, pandas
"""
import os

import pyreadstat

HERE = os.path.dirname(os.path.abspath(__file__))
SAV = os.path.join(HERE, "..", "data", "marketplace_x_clean.sav")
CSV = os.path.join(HERE, "..", "data", "marketplace_x_clean.csv")

df, meta = pyreadstat.read_sav(SAV)
# Whole-number columns are written without ".0" (as PSPP does); other columns keep their decimals
for c in df.columns:
    s = df[c].dropna()
    if len(s) and (s == s.round()).all():
        df[c] = df[c].astype("Int64")
df.to_csv(CSV, index=False)
print(f"saved {CSV}: {len(df)} rows, {len(df.columns)} columns")
