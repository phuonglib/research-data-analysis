"""
Cronbach's alpha (3 decimals), mean inter-item correlation and McDonald's omega
for the five scales of Post 11.

PSPP has no command for omega. The script fits a one-factor principal axis factoring (PAF)
to the correlation matrix of each scale:  omega = (sum of loadings)^2 / ((sum of loadings)^2 + sum(1 - loading^2)).

Run:    python compute_omega.py
Input:  ../data/marketplace_x_analysis.csv  (exported from the .sav: pspp-convert marketplace_x_analysis.sav marketplace_x_analysis.csv)
Needs:  pandas, numpy
"""
import os

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "..", "data", "marketplace_x_analysis.csv")).apply(pd.to_numeric, errors="coerce")

SCALES = {
    "CONF": ["CONF1", "CONF2", "CONF3", "CONF4"],
    "PV": ["PV1", "PV2", "PV3", "PV4"],
    "SAT": ["SAT1", "SAT2", "SAT3", "SAT4"],
    "TRU": ["TRU1", "TRU2", "TRU3", "TRU4R"],
    "RI": ["RI1", "RI2", "RI3", "RI4"],
}


def cronbach_alpha(x):
    k = x.shape[1]
    return k / (k - 1) * (1 - x.var(ddof=1).sum() / x.sum(axis=1).var(ddof=1))


def paf_one_factor(r, n_iter=500):
    h2 = 1 - 1 / np.diag(np.linalg.inv(r))          # start with the SMC
    for _ in range(n_iter):
        rr = r.copy()
        np.fill_diagonal(rr, h2)
        w, v = np.linalg.eigh(rr)
        lam = v[:, -1] * np.sqrt(w[-1])
        h2 = lam ** 2
    return np.abs(lam)


print(f"{'Scale':<7}{'N':>5}{'Alpha':>8}{'Omega':>8}{'Mean r':>8}  Loadings")
for name, items in SCALES.items():
    x = df[items].dropna()                           # listwise deletion, as in PSPP
    r = x.corr().values
    lam = paf_one_factor(r)
    omega = lam.sum() ** 2 / (lam.sum() ** 2 + (1 - lam ** 2).sum())
    mean_r = r[np.triu_indices(len(items), 1)].mean()
    print(f"{name:<7}{len(x):>5}{cronbach_alpha(x):>8.3f}{omega:>8.3f}{mean_r:>8.3f}  {np.round(lam, 2)}")
