"""
Cross-check of the Post 15 assumption tests in Python, plus two statistics PSPP does not offer:
bootstrap confidence intervals and HC3 robust standard errors.

Run:    python check_python.py   (output saved in check_python_output.txt)
Input:  ../data/marketplace_x_analysis.csv
Needs:  pip install pandas numpy scipy statsmodels
"""
import os

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy import stats
from statsmodels.stats.diagnostic import het_breuschpagan, linear_reset
from statsmodels.stats.stattools import durbin_watson

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "..", "data", "marketplace_x_analysis.csv")).apply(pd.to_numeric, errors="coerce")
d = df[["ID", "CONF", "PV", "SAT", "TRU", "RI"]].dropna().sort_values("ID")
m = smf.ols("RI ~ CONF + PV + SAT + TRU", d).fit()
inf = m.get_influence()

print(f"N = {int(m.nobs)}; R2 = {m.rsquared:.3f}")
print("Tolerance and VIF:")
X = d[["CONF", "PV", "SAT", "TRU"]]
for v in X.columns:
    r2 = smf.ols(f"{v} ~ " + " + ".join(c for c in X.columns if c != v), d).fit().rsquared
    print(f"  {v:<5} tolerance = {1 - r2:.3f}   VIF = {1 / (1 - r2):.3f}")
print("RESET (squared predicted value):", linear_reset(m, power=2, use_f=True))
lm, lm_p, f, f_p = het_breuschpagan(m.resid, m.model.exog, robust=True)
print(f"Breusch-Pagan (Koenker): LM = {lm:.2f}, p = {lm_p:.3f}; F = {f:.2f}, p = {f_p:.3f}")
print(f"Durbin-Watson = {durbin_watson(m.resid):.3f}")
w, p = stats.shapiro(m.resid)
print(f"Shapiro-Wilk: W = {w:.3f}, p = {p:.2e}; skewness = {stats.skew(m.resid, bias=False):.2f}")
cook, h, sr = inf.cooks_distance[0], inf.hat_matrix_diag, inf.resid_studentized_internal
print(f"Largest Cook's distance = {cook.max():.3f} (response {int(d.ID.values[cook.argmax()])}); "
      f"responses with Cook > 4/N: {(cook > 4 / len(d)).sum()}")
print(f"Largest leverage = {h.max():.3f}; responses above 2(k+1)/N: {(h > 10 / len(d)).sum()}")
print(f"Responses with |studentized residual| > 3: {(np.abs(sr) > 3).sum()}")

hc3 = m.get_robustcov_results("HC3")
print("\nOLS and HC3 standard errors:")
for name, se, se3, p3 in zip(m.params.index, m.bse, hc3.bse, hc3.pvalues):
    print(f"  {name:<10} OLS {se:.3f}   HC3 {se3:.3f}   p(HC3) = {p3:.4f}")

rng = np.random.default_rng(15)
x = d[["CONF", "PV", "SAT", "TRU", "RI"]].values
B = []
for _ in range(5000):
    s = x[rng.integers(0, len(x), len(x))]
    B.append(np.linalg.lstsq(np.c_[np.ones(len(s)), s[:, :4]], s[:, 4], rcond=None)[0])
lo, hi = np.percentile(np.array(B), [2.5, 97.5], axis=0)
ci = m.conf_int()
print("\n95% confidence intervals: OLS and bootstrap (5,000 resamples)")
for i, name in enumerate(m.params.index):
    print(f"  {name:<10} OLS [{ci.iloc[i, 0]:.3f}; {ci.iloc[i, 1]:.3f}]   bootstrap [{lo[i]:.3f}; {hi[i]:.3f}]")

# Sensitivity analysis: without the responses with Cook > 4/N
keep = cook <= 4 / len(d)
m2 = smf.ols("RI ~ CONF + PV + SAT + TRU", d[keep]).fit()
zs = lambda mm, dd: mm.params[1:] * dd[["CONF", "PV", "SAT", "TRU"]].std() / dd.RI.std()
print(f"\nSensitivity: N = {int(m2.nobs)}, R2 = {m2.rsquared:.3f} (full: {m.rsquared:.3f})")
for v in ["CONF", "PV", "SAT", "TRU"]:
    print(f"  {v:<5} beta {zs(m, d)[v]:.3f} p {m.pvalues[v]:.3f}   |   beta {zs(m2, d[keep])[v]:.3f} p {m2.pvalues[v]:.4f}")
