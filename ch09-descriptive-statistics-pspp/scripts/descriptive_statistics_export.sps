* Export the clean data to CSV to draw the stacked bar chart in Python (make_figures.py).
GET FILE='../data/marketplace_x_clean.sav'.
SAVE TRANSLATE /OUTFILE='../data/marketplace_x_clean.csv' /TYPE=CSV /FIELDNAMES /REPLACE.
