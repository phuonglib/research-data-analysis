* =====================================================================.
* Post 9. Descriptive statistics: describe the sample and the study variables.
* Data: marketplace_x_clean.sav (267 responses, cleaned in Post 8).
* Run from the scripts folder: pspp --syntax-encoding=UTF-8 descriptive_statistics.sps
* =====================================================================.
GET FILE='../data/marketplace_x_clean.sav'.

* Part 1. Sample profile: nominal and ordinal variables use frequencies.
FREQUENCIES GENDER OCCUP INCOME /STATISTICS=NONE /BARCHART.

* Part 2. Quantitative (Scale) variables: mean, median, standard deviation, skewness, kurtosis.
FREQUENCIES AGE FREQ /FORMAT=NOTABLE
  /STATISTICS=MEAN MEDIAN STDDEV MINIMUM MAXIMUM SKEWNESS SESKEW KURTOSIS SEKURT
  /PERCENTILES=25 75 /HISTOGRAM=NORMAL.

* Part 3. Likert items: mean, standard deviation, skewness and kurtosis.
DESCRIPTIVES CONF1 TO SAT2 SAT3 TO RI4
  /STATISTICS=MEAN STDDEV MIN MAX SKEWNESS KURTOSIS.

* Frequency distribution of each answer level (example: the Satisfaction scale).
FREQUENCIES SAT1 SAT2 SAT3 SAT4 /STATISTICS=MEDIAN MODE.

* Part 4. Description by group: mean of item RI1 by gender and income.
* MEANS prints the statistics in the display format of each variable, here whole numbers.
* For two decimals, first run the command FORMATS AGE FREQ RI1 (F5.2) (see section 6 of the post).
MEANS TABLES=AGE FREQ RI1 BY GENDER /CELLS=MEAN COUNT STDDEV.
CROSSTABS /TABLES=OCCUP BY INCOME /CELLS=COUNT ROW.
