"""
Supplementary calculations for Post 12 that PSPP does not offer:
  1. MSA of each item (item-level KMO) and the determinant of the correlation matrix
  2. Parallel analysis (Horn, 1965) to decide the number of factors, on the full correlation matrix
     (PCA style) and on the reduced correlation matrix (PAF style)
  3. The parallel-analysis chart (fig-9-parallel-analysis.png)
Fixed random seed, so the results are reproducible.

Run:    python efa_supplement.py --fonts ../fonts --out ../images
Input:  ../data/marketplace_x_analysis.csv
Needs:  pandas, numpy, matplotlib
"""
import argparse
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import font_manager

HERE = os.path.dirname(os.path.abspath(__file__))
ITEMS = ["CONF1", "CONF2", "CONF3", "CONF4", "PV1", "PV2", "PV3", "PV4", "SAT1", "SAT2", "SAT3", "SAT4",
         "TRU1", "TRU2", "TRU3", "TRU4R", "RI1", "RI2", "RI3", "RI4"]
NAVY, TEAL, ORANGE, MUTED = "#1F3A5F", "#2A8C7E", "#C2562E", "#5B6472"


def kmo(r):
    ri = np.linalg.inv(r)
    d = np.sqrt(np.outer(np.diag(ri), np.diag(ri)))
    p = -ri / d                                   # partial correlations
    np.fill_diagonal(p, 0)
    r0 = r.copy(); np.fill_diagonal(r0, 0)
    msa = (r0 ** 2).sum(0) / ((r0 ** 2).sum(0) + (p ** 2).sum(0))
    overall = (r0 ** 2).sum() / ((r0 ** 2).sum() + (p ** 2).sum())
    return overall, msa


def eig_full(r):
    return np.sort(np.linalg.eigvalsh(r))[::-1]


def eig_reduced(r):
    """Eigenvalues of the reduced correlation matrix (diagonal replaced by the SMCs), as used by PAF."""
    rr = r.copy()
    np.fill_diagonal(rr, 1 - 1 / np.diag(np.linalg.inv(r)))
    return np.sort(np.linalg.eigvalsh(rr))[::-1]


def parallel(n, k, fun, reps=1000, seed=2026):
    rng = np.random.default_rng(seed)
    ev = np.array([fun(np.corrcoef(rng.standard_normal((n, k)), rowvar=False)) for _ in range(reps)])
    return np.percentile(ev, 95, axis=0)


def run(fonts, out):
    df = pd.read_csv(os.path.join(HERE, "..", "data", "marketplace_x_analysis.csv")).apply(pd.to_numeric, errors="coerce")
    x = df[ITEMS].dropna()
    n, k = x.shape
    r = np.corrcoef(x.values, rowvar=False)
    overall, msa = kmo(r)
    print(f"N = {n}; determinant = {np.linalg.det(r):.2e}; KMO = {overall:.3f}")
    print("Item MSA:", ", ".join(f"{c} {m:.2f}" for c, m in zip(ITEMS, msa)))
    print(f"Lowest MSA: {msa.min():.3f} ({ITEMS[msa.argmin()]}); highest: {msa.max():.3f} ({ITEMS[msa.argmax()]})")
    res = {}
    for name, fun in [("PCA", eig_full), ("PAF", eig_reduced)]:
        ev, p95 = fun(r), parallel(n, k, fun)
        keep = int((ev > p95).cumprod().sum())
        res[name] = (ev, p95, keep)
        print(f"\nParallel analysis based on {name}: keep {keep} factors")
        print("Factor  Eigenvalue  Random (95th pct)")
        for i in range(8):
            print(f"{i + 1:>6} {ev[i]:>11.3f} {p95[i]:>18.3f}")

    for f in os.listdir(fonts):
        if f.endswith(".ttf"):
            font_manager.fontManager.addfont(os.path.join(fonts, f))
    plt.rcParams["font.family"] = "Be Vietnam Pro"
    fig, axes = plt.subplots(1, 2, figsize=(10, 4.8), dpi=200)
    fig.subplots_adjust(left=0.07, right=0.98, top=0.76, bottom=0.13, wspace=0.22)
    t = np.arange(1, 11)
    titles = {"PCA": "Full correlation matrix (PCA style)", "PAF": "Reduced correlation matrix (PAF style)"}
    for ax, name in zip(axes, ["PCA", "PAF"]):
        ev, p95, keep = res[name]
        ax.plot(t, ev[:10], "-o", color=NAVY, lw=2, ms=5, label="Real data")
        ax.plot(t, p95[:10], "--", color=ORANGE, lw=1.8, label="Random data (95th percentile)")
        ax.scatter(t[:keep], ev[:keep], s=70, facecolor="none", edgecolor=TEAL, lw=1.8, zorder=5)
        ax.set_title(f"{titles[name]}: keep {keep} factors", fontsize=10, color=NAVY, loc="left", fontweight="bold")
        ax.set_xticks(t); ax.tick_params(labelsize=8.5, colors=MUTED)
        ax.set_xlabel("Factor number", fontsize=9, color=MUTED)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        ax.grid(axis="y", color="#E5E7EB", lw=0.8)
        ax.legend(frameon=False, fontsize=8.5, loc="upper right")
    axes[0].axhline(1, color=MUTED, lw=0.9, ls=":")
    axes[0].text(10, 0.93, "Eigenvalue = 1", ha="right", va="top", fontsize=8, color=MUTED)
    axes[0].set_ylabel("Eigenvalue", fontsize=9, color=MUTED)
    fig.text(0.04, 0.94, "Parallel analysis: two ways of computing, two conclusions", fontsize=14, fontweight="bold", color=NAVY)
    fig.text(0.04, 0.895, f"N = {n}, 20 items; teal circles mark factors whose eigenvalue beats random data (1,000 simulations)",
             fontsize=9, color=MUTED)
    os.makedirs(out, exist_ok=True)
    fig.savefig(os.path.join(out, "fig-9-parallel-analysis.png"), facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--fonts", default=os.path.join(HERE, "..", "fonts"))
    ap.add_argument("--out", default=os.path.join(HERE, "..", "images"))
    a = ap.parse_args()
    run(a.fonts, a.out)
