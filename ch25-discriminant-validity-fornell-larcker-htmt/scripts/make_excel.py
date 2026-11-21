"""Build htmt_fornell_larcker_template.xlsx (Post 25): HTMT from the item correlation matrix and the Fornell-Larcker
criterion. Both sheets compute with Excel formulas; the yellow cells hold the sample data and can be overwritten.
Inputs: ../data/marketplace_x_sem.csv, fornell_larcker.csv and ave.csv (written by discriminant_validity.R).
Run:  python make_excel.py   (from the scripts folder)"""
import os
import pandas as pd
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter as L

HERE = os.path.dirname(os.path.abspath(__file__))
d = pd.read_csv(os.path.join(HERE, '..', 'data', 'marketplace_x_sem.csv')).apply(pd.to_numeric, errors='coerce')
items = ([f'CONF{i}' for i in range(1, 5)] + [f'PV{i}' for i in range(1, 5)] + [f'SAT{i}' for i in range(1, 5)]
         + ['TRU1', 'TRU2', 'TRU3', 'TRU4R'] + [f'RI{i}' for i in range(1, 5)])
R = d[items].corr()  # Pearson, pairwise deletion
fac = ['CONFIRM', 'VALUE', 'SATISF', 'TRUST', 'INTENT']
F = "Be Vietnam Pro"; hd = Font(name=F, bold=True, color="FFFFFF"); nf = Font(name=F); fill = PatternFill("solid", fgColor="1F3A5F")
inp = PatternFill("solid", fgColor="FFF4D6"); thin = Side(style="thin", color="C8CED6"); bd = Border(top=thin, bottom=thin, left=thin, right=thin)
note = Font(name=F, italic=True, color="5B6472")

wb = Workbook(); ws = wb.active; ws.title = "HTMT"
ws["A1"] = "HTMT from the correlation matrix of the items (Post 25)"; ws["A1"].font = Font(name=F, bold=True, size=13, color="1F3A5F")
ws["A2"] = "Paste the 20 × 20 correlation matrix (Pearson, pairwise) into the yellow range B5:U24, in the item order of row 4 and column A."
ws["A2"].font = note
for j, c in enumerate(items):
    x = ws.cell(4, j + 2, c); x.font = hd; x.fill = fill; x.alignment = Alignment(horizontal="center")
    y = ws.cell(5 + j, 1, c); y.font = hd; y.fill = fill
    for k, c2 in enumerate(items):
        z = ws.cell(5 + j, k + 2, round(float(R.loc[c, c2]), 4)); z.fill = inp; z.number_format = "0.000"
        z.font = Font(name=F, size=9); z.border = bd


def blk(i, j):
    r1, c1 = 5 + 4 * i, 2 + 4 * j
    return f"{L(c1)}{r1}:{L(c1 + 3)}{r1 + 3}"


r0 = 27
ws.cell(r0, 1, "HTMT matrix (Henseler et al., 2015)").font = Font(name=F, bold=True, size=12, color="1F3A5F")
ws.cell(r0 + 1, 1, "").fill = fill
for j, f in enumerate(fac):
    x = ws.cell(r0 + 1, j + 2, f); x.font = hd; x.fill = fill; x.alignment = Alignment(horizontal="center")
    y = ws.cell(r0 + 2 + j, 1, f); y.font = hd; y.fill = fill
wr = r0 + 8
ws.cell(wr, 1, "Average correlation within each scale (diagonal excluded)").font = note
for j, f in enumerate(fac):
    c = ws.cell(wr + 1, j + 2, f"=(SUM({blk(j, j)})-4)/12"); c.number_format = "0.000"; c.font = nf
for i in range(5):
    for j in range(5):
        c = ws.cell(r0 + 2 + i, j + 2)
        if i == j:
            c.value = 1
        elif i > j:
            c.value = f"=AVERAGE({blk(i, j)})/SQRT({L(i + 2)}{wr + 1}*{L(j + 2)}{wr + 1})"; c.number_format = "0.000"
        c.font = Font(name=F, bold=(i > j)); c.border = bd
ws.cell(wr + 3, 1, "Reading: HTMT below 0.85 (conservative threshold) or 0.90 (conceptually similar constructs): the two scales are distinct.").font = note
ws.cell(wr + 4, 1, "HTMT = average correlation between two scales / square root(product of the two average within-scale correlations).").font = note
ws.column_dimensions['A'].width = 13
for j in range(2, 23):
    ws.column_dimensions[L(j)].width = 8.5

ws2 = wb.create_sheet("Fornell_Larcker")
ws2["A1"] = "Fornell-Larcker criterion"; ws2["A1"].font = Font(name=F, bold=True, size=13, color="1F3A5F")
ws2["A2"] = "Paste AVE (from cr_ave_template.xlsx, Post 24) into row 4 and the correlations between factors into the lower triangle (yellow cells)."
ws2["A2"].font = note
fl = pd.read_csv(os.path.join(HERE, 'fornell_larcker.csv'), index_col=0)
ave = pd.read_csv(os.path.join(HERE, 'ave.csv')).set_index('construct')['AVE']
ws2.cell(4, 1, "AVE").font = hd; ws2.cell(4, 1).fill = fill; ws2.cell(6, 1, "").fill = fill
for j, f in enumerate(fac):
    c = ws2.cell(4, j + 2, round(float(ave[f]), 4)); c.fill = inp; c.number_format = "0.000"; c.font = nf
    x = ws2.cell(6, j + 2, f); x.font = hd; x.fill = fill
    y = ws2.cell(7 + j, 1, f); y.font = hd; y.fill = fill
for i in range(5):
    for j in range(5):
        c = ws2.cell(7 + i, j + 2)
        if i == j:
            c.value = f"=SQRT({L(j + 2)}4)"; c.font = Font(name=F, bold=True, color="2A8C7E")
        elif i > j:
            c.value = round(float(fl.iloc[i, j]), 4); c.fill = inp; c.font = nf
        c.number_format = "0.000"; c.border = bd
ws2.cell(13, 1, "Conclusion").font = Font(name=F, bold=True)
for j in range(5):
    col = L(j + 2); diag = f"{col}{7 + j}"
    others = [f"{L(k + 2)}{7 + j}" for k in range(j)] + [f"{col}{7 + k}" for k in range(j + 1, 5)]
    ws2.cell(13, j + 2, f'=IF({diag}>MAX({",".join(others)}),"Pass","Fail")').font = nf
ws2.cell(15, 1, "Pass when the square root of AVE (diagonal) is larger than every correlation of that factor with the other factors (same row and same column).").font = note
ws2.column_dimensions['A'].width = 13
for j in range(2, 8):
    ws2.column_dimensions[L(j)].width = 11
wb.save(os.path.join(HERE, '..', 'data', 'htmt_fornell_larcker_template.xlsx'))

# Values the formulas will show (checked against the post)
avg = {f: (R.loc[items[4*i:4*i+4], items[4*i:4*i+4]].values.sum() - 4) / 12 for i, f in enumerate(fac)}
for i in range(5):
    for j in range(i):
        h = R.loc[items[4*i:4*i+4], items[4*j:4*j+4]].values.mean() / (avg[fac[i]] * avg[fac[j]]) ** 0.5
        print(f"{fac[i]:8s} {fac[j]:8s} {h:.4f}")
