"""
Post 16 supplement: numbers quoted in the post that dummy_moderation.sps does not print.
  1. Standardized coefficients (beta) of Model 2 without the control variables, on the 259 complete cases
  2. F test of the R-square change when the four control dummies are added
  3. Gender as a categorical moderator (SAT_C x D_FEMALE)
  4. Age (in years, mean-centered) as a moderator of the SAT effect, one of the extra moderators tried
Run:  python supplement.py > supplement_output.txt
Needs: pandas, numpy, statsmodels, pyreadstat
"""
import os

import numpy as np
import pyreadstat
import statsmodels.formula.api as smf

HERE = os.path.dirname(os.path.abspath(__file__))
df, _ = pyreadstat.read_sav(os.path.join(HERE, "..", "data", "marketplace_x_analysis.sav"))
for k, name in [(2, "D_OFFICE"), (3, "D_SELFEMP"), (4, "D_OTHER")]:
    df[name] = np.where(df.OCCUP.isna(), np.nan, (df.OCCUP == k).astype(float))
df["D_FEMALE"] = df.GENDER.map({2: 1.0, 1: 0.0})          # "Other" (3) -> missing, as in the .sps
for c in ["CONF", "PV", "SAT", "TRU"]:
    df[c + "_C"] = df[c] - df[c].mean()

# 1-2. Control variables (same 259 cases as part 2c of the .sps)
c = df.dropna(subset=["CONF", "PV", "SAT", "TRU", "RI", "D_OFFICE", "D_FEMALE"]).copy()
print("Complete cases for the control-variable models:", len(c))
z = c.copy()
for v in ["CONF", "PV", "SAT", "TRU", "RI"]:
    z[v] = (z[v] - z[v].mean()) / z[v].std()
m0 = smf.ols("RI ~ CONF + PV + SAT + TRU", z).fit()
print("Model 2 without controls, standardized coefficients:")
print(m0.params.drop("Intercept").round(5).to_string())
a = smf.ols("RI ~ CONF + PV + SAT + TRU", c).fit()
b = smf.ols("RI ~ CONF + PV + SAT + TRU + D_OFFICE + D_SELFEMP + D_OTHER + D_FEMALE", c).fit()
F, p, dfn = b.compare_f_test(a)
print(f"R2 without controls = {a.rsquared:.4f}, with controls = {b.rsquared:.4f}, change = {b.rsquared - a.rsquared:.4f}")
print(f"F change({int(dfn)}, {int(b.df_resid)}) = {F:.3f}, p = {p:.3f}")
print("Respondents with GENDER = Other among cases complete on CONF-RI and OCCUP:",
      int((df.dropna(subset=["CONF", "PV", "SAT", "TRU", "RI", "D_OFFICE"]).GENDER == 3).sum()))

# 3. Gender as moderator
g = df.dropna(subset=["CONF", "PV", "SAT", "TRU", "RI", "D_FEMALE"])
mg = smf.ols("RI ~ CONF_C + PV_C + TRU_C + SAT_C * D_FEMALE", g).fit()
print(f"\nGender moderator (n = {int(mg.nobs)}): B(SAT_C x D_FEMALE) = {mg.params['SAT_C:D_FEMALE']:.3f}, "
      f"p = {mg.pvalues['SAT_C:D_FEMALE']:.3f}")

# 4. Age as moderator of the SAT effect
d = df.dropna(subset=["CONF", "PV", "SAT", "TRU", "RI", "AGE"]).copy()
d["AGE_C"] = d.AGE - d.AGE.mean()
ma = smf.ols("RI ~ CONF_C + PV_C + TRU_C + SAT_C * AGE_C", d).fit()
print(f"Age moderator (n = {int(ma.nobs)}): B(SAT_C x AGE_C) = {ma.params['SAT_C:AGE_C']:.4f}, "
      f"p = {ma.pvalues['SAT_C:AGE_C']:.3f}")
