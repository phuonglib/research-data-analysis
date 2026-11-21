"""
Post 18. Cross-check the PSPP results with Python (scipy, statsmodels).
Run:   python check_python.py            (writes the same text to check_python_output.txt)
Needs: pip install pandas scipy numpy statsmodels
"""
import os
import sys

import numpy as np
import pandas as pd
from scipy import stats
from statsmodels.stats.multicomp import pairwise_tukeyhsd
from statsmodels.stats.oneway import anova_oneway

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "..", "data", "marketplace_x_analysis.csv")).apply(pd.to_numeric, errors="coerce")
lines = []


def out(s=""):
    print(s)
    lines.append(str(s))


def one_way(y, g):
    d = df[[y, g]].dropna()
    groups = [x[y] for _, x in d.groupby(g)]
    f = stats.f_oneway(*groups)
    lev = stats.levene(*groups, center="mean")
    gm = d[y].mean()
    ssb = sum(len(x) * (x.mean() - gm) ** 2 for x in groups)
    sst = ((d[y] - gm) ** 2).sum()
    k, n = len(groups), len(d)
    msw = (sst - ssb) / (n - k)
    out(f"{y} by {g}: F({k - 1}, {n - k}) = {f.statistic:.2f}, p = {f.pvalue:.4f}; Levene F = {lev.statistic:.2f}, "
        f"p = {lev.pvalue:.3f}; SSB = {ssb:.2f}, SSW = {sst - ssb:.2f}, SST = {sst:.2f}; "
        f"eta2 = {ssb / sst:.3f}; omega2 = {(ssb - (k - 1) * msw) / (sst + msw):.3f}")
    return d


d = one_way("RI", "INCOME")
out(d.groupby("INCOME").RI.agg(["count", "mean", "std"]).round(2))
w = anova_oneway(d.RI, d.INCOME, use_var="unequal")
out(f"  Welch F(3, {w.df_denom:.2f}) = {w.statistic:.2f}, p = {w.pvalue:.6f}")
kw = stats.kruskal(*[x.RI for _, x in d.groupby("INCOME")])
out(f"  Kruskal-Wallis H = {kw.statistic:.2f}, p = {kw.pvalue:.3f}")
out(pairwise_tukeyhsd(d.RI, d.INCOME))
means = d.groupby("INCOME").RI.mean().values
c = np.array([-3, -1, 1, 3])
out(f"  Linear trend contrast: value = {(c * means).sum():.4f}")
one_way("RI", "OCCUP")
one_way("RI", "AGEGROUP")
with open(os.path.join(HERE, "check_python_output.txt"), "w") as fh:
    fh.write("\n".join(lines) + "\n")
