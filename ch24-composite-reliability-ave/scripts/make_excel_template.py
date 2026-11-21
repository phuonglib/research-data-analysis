"""
Build data/cr_ave_template.xlsx: CR and AVE from standardized loadings (Post 24).
Yellow cells (column C) hold the standardized loadings of the sample data (JASP "Std. estimate",
4 decimals, equal to loadings.csv from cr_ave.R); columns D, E and the summary table are formulas.
Run:  python make_excel_template.py
"""
import csv
import os

from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

HERE = os.path.dirname(os.path.abspath(__file__))
HEAD = PatternFill("solid", fgColor="1F3A5F")
YELLOW = PatternFill("solid", fgColor="FFF4D6")
WHITE_B = Font(bold=True, color="FFFFFF")

rows = list(csv.DictReader(open(os.path.join(HERE, "loadings.csv"), encoding="utf-8")))
wb = Workbook()
ws = wb.active
ws.title = "CR_AVE"
ws["A1"] = "CR and AVE from standardized loadings (Post 24)"
ws["A1"].font = Font(bold=True, size=13)
ws["A2"] = "Paste the standardized loadings into column C (yellow cells). Columns D, E and the summary table are calculated."
for col, text in zip("ABCDE", ["Factor", "Item", "Standardized loading (L)", "L²", "Error (1 − L²)"]):
    ws[f"{col}4"] = text
    ws[f"{col}4"].fill, ws[f"{col}4"].font = HEAD, WHITE_B
for i, r in enumerate(rows, start=5):
    ws[f"A{i}"], ws[f"B{i}"] = r["lhs"], r["rhs"]
    ws[f"C{i}"] = round(float(r["std.all"]), 4)
    ws[f"C{i}"].fill = YELLOW
    ws[f"D{i}"], ws[f"E{i}"] = f"=C{i}^2", f"=1-D{i}"
    for c in "CDE":
        ws[f"{c}{i}"].number_format = "0.000"
ws["A26"] = "Summary"
ws["A26"].font = Font(bold=True)
heads = ["Factor", "Items", "Sum L", "Sum L²", "Sum error", "CR", "AVE", "Square root of AVE", "CR at least 0.7",
         "AVE at least 0.5"]
for col, text in zip("ABCDEFGHIJ", heads):
    ws[f"{col}27"] = text
    ws[f"{col}27"].fill, ws[f"{col}27"].font = HEAD, WHITE_B
for j, f in enumerate(["CONFIRM", "VALUE", "SATISF", "TRUST", "INTENT"]):
    r, a, b = 28 + j, 5 + 4 * j, 8 + 4 * j
    ws[f"A{r}"] = f
    ws[f"B{r}"] = f"=COUNT(C{a}:C{b})"
    ws[f"C{r}"], ws[f"D{r}"], ws[f"E{r}"] = f"=SUM(C{a}:C{b})", f"=SUM(D{a}:D{b})", f"=SUM(E{a}:E{b})"
    ws[f"F{r}"] = f"=C{r}^2/(C{r}^2+E{r})"
    ws[f"G{r}"] = f"=D{r}/B{r}"
    ws[f"H{r}"] = f"=SQRT(G{r})"
    ws[f"I{r}"] = f'=IF(F{r}>=0.7,"Met","Not met")'
    ws[f"J{r}"] = f'=IF(G{r}>=0.5,"Met","Not met")'
    for c in "CDEFGH":
        ws[f"{c}{r}"].number_format = "0.000"
ws["A34"] = "Formulas (Fornell & Larcker, 1981; Hair et al., 2019):"
ws["A35"] = "CR = (Sum L)² / [(Sum L)² + Sum error]"
ws["A36"] = "AVE = Sum L² / number of items"
ws["A37"] = ("Use fully standardized loadings only (Standardized Regression Weights in AMOS; "
             "Std. estimate in JASP).")
for col, wdt in zip("ABCDEFGHIJ", [12, 10, 14, 10, 12, 10, 10, 12, 12, 12]):
    ws.column_dimensions[col].width = wdt
wb.save(os.path.join(HERE, "..", "data", "cr_ave_template.xlsx"))
print("Saved data/cr_ave_template.xlsx")
