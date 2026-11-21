"""
Sample size calculations for the running example of the series (repurchase intention on Marketplace X).

Model: 5 constructs (CONFIRM, VALUE, SATISF, TRUST, INTENT), 4 items each = 20 items.
Run:  python sample_size.py      (needs: pip install scipy)

Every number printed here is used in Post 4.
"""
import math
from scipy import stats

ALPHA, POWER = 0.05, 0.80
N_CONSTRUCTS, ITEMS_PER = 5, 4
P = N_CONSTRUCTS * ITEMS_PER          # number of items (indicators)


def regression_power_n(m, f2, alpha=ALPHA, power=POWER):
    """Minimum N for the F test of R-square in multiple regression
    (same as G*Power: Linear multiple regression, fixed model, R-square deviation from zero).
    Noncentrality parameter lambda = f2 * N."""
    n = m + 2
    while True:
        df1, df2 = m, n - m - 1
        crit = stats.f.ppf(1 - alpha, df1, df2)
        if 1 - stats.ncf.cdf(crit, df1, df2, f2 * n) >= power:
            return n
        n += 1


def rmsea_power_n(df, rmsea0=0.05, rmsea_a=0.08, alpha=ALPHA, power=POWER):
    """Minimum N for the test of close fit of MacCallum, Browne and Sugawara (1996)."""
    n = 10
    while True:
        lam0 = (n - 1) * df * rmsea0 ** 2
        lam_a = (n - 1) * df * rmsea_a ** 2
        crit = stats.ncx2.ppf(1 - alpha, df, lam0)
        if 1 - stats.ncx2.cdf(crit, df, lam_a) >= power:
            return n
        n += 1


def inverse_square_root_n(p_min):
    """Inverse square root method (Kock & Hadaya, 2018), 5% significance level, 80% power."""
    return math.ceil((2.486 / abs(p_min)) ** 2)


def cochran_n(p=0.5, e=0.05, z=1.96):
    return math.ceil(z ** 2 * p * (1 - p) / e ** 2)


def yamane_n(N, e=0.05):
    return math.ceil(N / (1 + N * e ** 2))


def cfa_free_params(k, p):
    loadings = p - k                  # one loading per construct is fixed to 1
    errors = p
    factor_var = k
    factor_cov = k * (k - 1) // 2
    return loadings + errors + factor_var + factor_cov


if __name__ == "__main__":
    print(f"Number of items p = {P}")
    print("\n1) EFA (Hair et al., 2019)")
    print(f"   Ratio 5:1  -> {5 * P}")
    print(f"   Ratio 10:1 -> {10 * P}")

    m = 3  # regression INTENT ~ VALUE + SATISF + TRUST
    print(f"\n2) Multiple regression with m = {m} predictors")
    print(f"   Green (1991): 50 + 8m = {50 + 8 * m};  104 + m = {104 + m}")
    for f2, lab in [(0.02, 'small'), (0.15, 'medium'), (0.35, 'large')]:
        print(f"   Power analysis, f2 = {f2} ({lab}): N = {regression_power_n(m, f2)}")

    print("\n3) PLS-SEM, inverse square root method")
    for pm in [0.10, 0.15, 0.20, 0.25, 0.30]:
        print(f"   p_min = {pm:.2f} -> N = {inverse_square_root_n(pm)}")
    print(f"   Smallest detectable path with N = 250: {2.486 / math.sqrt(250):.3f}")

    q = cfa_free_params(N_CONSTRUCTS, P)
    moments = P * (P + 1) // 2
    df = moments - q
    print(f"\n4) CB-SEM (CFA with {N_CONSTRUCTS} constructs): free parameters q = {q}, df = {df}")
    print(f"   Ratio N:q 10:1 -> {10 * q};  20:1 -> {20 * q}")
    print(f"   RMSEA power (0.05 vs 0.08): N = {rmsea_power_n(df)}")

    print("\n5) Estimating a proportion (descriptive)")
    print(f"   Cochran (p = 0.5, e = 5%): {cochran_n()}")
    for N in [500, 2000, 100000]:
        print(f"   Yamane with N = {N}: {yamane_n(N)}")

    target, loss = 250, 0.15
    print(f"\n6) Questionnaires to distribute: target {target} valid, {loss:.0%} allowance "
          f"-> {target / (1 - loss):.1f}, rounded up to {math.ceil(target / (1 - loss))}")
