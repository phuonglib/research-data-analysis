"""
Post 17. Check the PSPP results with Python (scipy).
Also runs the equivalence test (TOST) used in Section 7.
Run:   python check_python.py   (from the scripts/ folder; output saved in check_python_output.txt)
Needs: pip install pandas scipy numpy
"""
import os

import numpy as np
import pandas as pd
from scipy import stats

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "..", "data", "marketplace_x_analysis.csv")).apply(pd.to_numeric, errors="coerce")


def cohen_d(a, b):
    sp = np.sqrt(((len(a) - 1) * a.var() + (len(b) - 1) * b.var()) / (len(a) + len(b) - 2))
    return (a.mean() - b.mean()) / sp


print("1. Independent samples (Male = 1, Female = 2)")
for v in ["RI", "SAT", "FREQ"]:
    a = df.loc[df.GENDER == 1, v].dropna(); b = df.loc[df.GENDER == 2, v].dropna()
    lev = stats.levene(a, b, center="mean")
    st = stats.ttest_ind(a, b); we = stats.ttest_ind(a, b, equal_var=False)
    mw = stats.mannwhitneyu(a, b)
    print(f"  {v}: n = {len(a)}/{len(b)}, mean = {a.mean():.3f}/{b.mean():.3f}, SD = {a.std():.2f}/{b.std():.2f}, "
          f"Levene F = {lev.statistic:.2f} p = {lev.pvalue:.3f}; Student t = {st.statistic:.2f} p = {st.pvalue:.3f}; "
          f"Welch t = {we.statistic:.2f} df = {we.df:.2f} p = {we.pvalue:.3f}; diff = {a.mean() - b.mean():.3f}; "
          f"d = {cohen_d(a, b):.3f}; Mann-Whitney U = {mw.statistic:.1f} p = {mw.pvalue:.3f}")
no99 = df[df.ID != 99]
a = no99.loc[no99.GENDER == 1, "FREQ"].dropna(); b = no99.loc[no99.GENDER == 2, "FREQ"].dropna()
print(f"  FREQ without response ID 99: SD = {a.std():.2f}/{b.std():.2f}, "
      f"Welch p = {stats.ttest_ind(a, b, equal_var=False).pvalue:.3f}")

# Equivalence test (TOST) for RI by gender, bounds -0.2 and +0.2, Welch standard error and df
a = df.loc[df.GENDER == 1, "RI"].dropna(); b = df.loc[df.GENDER == 2, "RI"].dropna()
diff = a.mean() - b.mean()
va, vb = a.var() / len(a), b.var() / len(b)
se = np.sqrt(va + vb)
dfw = (va + vb) ** 2 / (va ** 2 / (len(a) - 1) + vb ** 2 / (len(b) - 1))
p_low = stats.t.sf((diff + 0.2) / se, dfw)      # H0: diff <= -0.2
p_high = stats.t.cdf((diff - 0.2) / se, dfw)    # H0: diff >= +0.2
q = stats.t.ppf(0.95, dfw)
print(f"  TOST RI (bounds +/-0.2): 90% CI [{diff - q * se:.3f}; {diff + q * se:.3f}], "
      f"p (lower) = {p_low:.3f}, p (upper) = {p_high:.3f}")

print("2. Paired samples PV2 - PV3")
p = df[["PV2", "PV3"]].dropna(); d = p.PV2 - p.PV3
r = stats.ttest_rel(p.PV2, p.PV3); ci = r.confidence_interval()
w = stats.wilcoxon(p.PV2, p.PV3, zero_method="wilcox", correction=False, method="approx")
print(f"  N = {len(p)}, mean diff = {d.mean():.3f}, SD = {d.std():.3f}, t = {r.statistic:.2f}, p = {r.pvalue:.3f}, "
      f"CI [{ci.low:.3f}; {ci.high:.3f}], r = {p.PV2.corr(p.PV3):.3f}, d_z = {d.mean() / d.std():.3f}")
print(f"  Wilcoxon: negative = {(d < 0).sum()}, positive = {(d > 0).sum()}, ties = {(d == 0).sum()}, p = {w.pvalue:.3f}")

print("3. One sample")
for g in [3, 4]:
    for v in ["SAT", "RI"]:
        x = df[v].dropna(); r = stats.ttest_1samp(x, g); ci = r.confidence_interval()
        print(f"  {v} against {g}: mean = {x.mean():.3f}, t({len(x) - 1}) = {r.statistic:.2f}, p = {r.pvalue:.4f}, "
              f"diff = {x.mean() - g:.3f} [{ci.low - g:.3f}; {ci.high - g:.3f}], d = {(x.mean() - g) / x.std():.3f}")
