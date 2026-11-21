# Research Data Analysis: sample data and scripts

Sample data, syntax files and cross-check scripts for the tutorial series on quantitative research data analysis with SPSS/PSPP, JASP, AMOS and SmartPLS on [phuonglib.com](https://www.phuonglib.com).

The data are **simulated** for a running example, "factors that drive customers' repurchase intention on an online marketplace (Marketplace X)". They are for learning only and are not results of a real survey.

## How to download

- Whole repository: click **Code > Download ZIP** on the main page of the repository, then unzip.
- Each `chNN-...` folder belongs to one post (table below). `data/` holds the data files, `scripts/` the PSPP/SPSS syntax (`.sps`), R scripts (`.R`), Python scripts (`.py`) and saved outputs, `raw/` the full program output as PDF where available. Scripts read data with relative paths, so keep the folder structure and run each script from inside its `scripts/` folder.
- Notes inside the files may say "Post N"; N is the chapter number in the folder name.

## Shared data (`00-shared-data`)

| File | Content |
|---|---|
| `marketplace_x_raw.*` | Raw survey export with the errors used in the data-cleaning post |
| `marketplace_x_clean.sav` | Cleaned data (267 respondents) |
| `marketplace_x_analysis.*` | Cleaned data with composite scores, used from the regression posts on |
| `marketplace_x_sem.*`, `marketplace_x_sem_complete.sav` | Data for CFA and SEM in JASP/AMOS (all cases with missing cells kept; complete cases only) |
| `marketplace_x_multigroup*.sav`, `marketplace_x_product*` | Data for the multigroup analysis post |
| `marketplace_x_smartpls.csv` | Data for SmartPLS 4 |
| `post07/` | Practice files for importing data from Excel and Google Forms |

Constructs and items: Confirmation (CONF1–CONF4), Perceived value (PV1–PV4), Satisfaction (SAT1–SAT4), Trust (TRU1–TRU3, TRU4R reverse-coded), Repurchase intention (RI1–RI4); profile variables GENDER, AGEGROUP, OCCUP, INCOME.

## Software

- PSPP (free) or IBM SPSS Statistics for `.sav` and `.sps` files.
- JASP (free) for CFA and SEM; AMOS opens the `.sav` files.
- R with the packages lavaan, semTools and cSEM to run the `.R` cross-checks.
- SmartPLS 4 imports `marketplace_x_smartpls.csv`.

## Folders by post

| Folder | Post |
|---|---|
| `00-shared-data` | Shared data sets |
| `ch04-sample-size-calculation` | [Sample Size Calculation for EFA, Regression, PLS-SEM and CB-SEM](https://www.phuonglib.com/p/sample-size-calculation) |
| `ch05-what-is-pspp-install-interface` | [What Is PSPP? Installing the Free SPSS Alternative and Its Interface](https://www.phuonglib.com/p/what-is-pspp-install-interface) |
| `ch06-define-code-variables-pspp` | [Defining and Coding Variables in PSPP (SPSS): From Questionnaire to Data](https://www.phuonglib.com/p/define-code-variables-pspp-spss) |
| `ch07-import-excel-google-forms-pspp` | [Importing Excel and Google Forms Data into PSPP (SPSS) Without Errors](https://www.phuonglib.com/p/import-data-excel-google-forms-pspp-spss) |
| `ch08-data-cleaning-missing-values-outliers-pspp` | [Data Cleaning in SPSS and PSPP: Missing Values and Outliers](https://www.phuonglib.com/p/data-cleaning-missing-values-outliers-spss-pspp) |
| `ch09-descriptive-statistics-pspp` | [Descriptive Statistics in SPSS and PSPP: Frequencies, Means and Spread](https://www.phuonglib.com/p/descriptive-statistics-spss-pspp) |
| `ch10-recode-compute-composite-scores-pspp` | [Recode and Compute Composite Scores in SPSS and PSPP](https://www.phuonglib.com/p/recode-compute-composite-scores-pspp-spss) |
| `ch11-cronbach-alpha-pspp` | [Cronbach's Alpha in SPSS and PSPP: How to Run, Read and Drop Items](https://www.phuonglib.com/p/cronbach-alpha-spss-pspp) |
| `ch12-exploratory-factor-analysis-efa-pspp` | [Exploratory Factor Analysis (EFA) in SPSS and PSPP, Step by Step](https://www.phuonglib.com/p/exploratory-factor-analysis-efa-pspp-spss) |
| `ch13-pearson-correlation-pspp` | [Pearson Correlation in SPSS and PSPP: Run, Read and Report It](https://www.phuonglib.com/p/pearson-correlation-pspp-spss) |
| `ch14-multiple-linear-regression-pspp` | [Multiple Linear Regression in SPSS and PSPP: Output and Hypotheses](https://www.phuonglib.com/p/multiple-linear-regression-pspp-spss) |
| `ch15-regression-assumptions-pspp` | [Regression Assumptions in PSPP (SPSS): Residuals, VIF and Influential Cases](https://www.phuonglib.com/p/regression-assumptions-spss-pspp) |
| `ch16-dummy-variables-moderation-regression-pspp` | [Dummy Variables and Moderator Variables in Regression with PSPP (SPSS)](https://www.phuonglib.com/p/dummy-variables-moderation-regression-pspp-spss) |
| `ch17-t-test-independent-paired-one-sample-pspp` | [T-Tests in PSPP (SPSS): Independent, Paired and One-Sample Tests](https://www.phuonglib.com/p/t-test-independent-paired-one-sample-pspp-spss) |
| `ch18-one-way-anova-post-hoc-pspp` | [One-Way ANOVA and Post-Hoc Tests in PSPP (SPSS): Run, Read and Report](https://www.phuonglib.com/p/one-way-anova-post-hoc-spss-pspp) |
| `ch19-what-is-amos-cb-sem` | [What Is AMOS? CB-SEM and When to Use It Instead of SPSS](https://www.phuonglib.com/p/what-is-amos-cb-sem) |
| `ch20-amos-jasp-interface-first-model` | [Your First Model in JASP: A Free Alternative to AMOS for CFA and SEM](https://www.phuonglib.com/p/first-model-jasp-free-amos-alternative) |
| `ch21-prepare-data-amos-jasp` | [Preparing SPSS Data for CFA and SEM in JASP, a Free AMOS Alternative](https://www.phuonglib.com/p/prepare-connect-data-spss-to-jasp) |
| `ch22-confirmatory-factor-analysis-cfa` | [Confirmatory Factor Analysis (CFA) in JASP: Output and Mardia's Test](https://www.phuonglib.com/p/confirmatory-factor-analysis-cfa-jasp) |
| `ch23-model-fit-indices-cfa` | [SEM Model Fit Indices in JASP: CMIN/df, GFI, CFI, TLI, RMSEA, SRMR](https://www.phuonglib.com/p/model-fit-indices-sem-jasp) |
| `ch24-composite-reliability-ave` | [Composite Reliability (CR) and AVE in JASP: Compute and Read Them](https://www.phuonglib.com/p/composite-reliability-ave-cfa-jasp) |
| `ch25-discriminant-validity-fornell-larcker-htmt` | [Convergent and Discriminant Validity in JASP: Fornell-Larcker and HTMT](https://www.phuonglib.com/p/convergent-discriminant-validity-cfa-jasp) |
| `ch26-structural-equation-model-sem` | [Structural Equation Model (SEM) in JASP: Specify, Run and Read Results](https://www.phuonglib.com/p/structural-equation-model-sem-jasp) |
| `ch27-hypothesis-testing-sem` | [Hypothesis Testing in SEM with JASP: Coefficients, p-Values and f²](https://www.phuonglib.com/p/hypothesis-testing-sem-jasp) |
| `ch28-mediation-analysis-bootstrap-sem` | [Mediation Analysis with JASP: Bootstrapping Specific Indirect Effects](https://www.phuonglib.com/p/mediation-analysis-bootstrap-jasp) |
| `ch29-multigroup-analysis-moderation-sem` | [Multigroup Analysis and Moderation in JASP: Invariance and Path Tests](https://www.phuonglib.com/p/multigroup-analysis-moderation-jasp) |
| `ch30-common-method-bias-harman-clf` | [Common Method Bias in JASP: Harman's Test and the Common Latent Factor](https://www.phuonglib.com/p/common-method-bias-jasp-harman-clf) |
| `ch31-what-is-smartpls-pls-sem-vs-cb-sem` | [What Is SmartPLS? PLS-SEM vs CB-SEM and When to Use Each](https://www.phuonglib.com/p/what-is-smartpls-pls-sem-vs-cb-sem) |
| `ch33-import-data-draw-model-smartpls` | [Importing Data and Drawing a PLS-SEM Model in SmartPLS 4](https://www.phuonglib.com/p/import-data-draw-model-smartpls-4) |
| `ch34-evaluate-reflective-measurement-model` | [Reflective Measurement Model in SmartPLS 4: Loadings, Reliability and AVE](https://www.phuonglib.com/p/evaluate-reflective-measurement-model-smartpls) |
| `ch35-htmt-discriminant-validity` | [Discriminant Validity in SmartPLS 4 with HTMT and Fornell-Larcker](https://www.phuonglib.com/p/htmt-discriminant-validity-smartpls) |
| `ch36-formative-measurement-models` | [Formative Measurement in SmartPLS 4: Redundancy Analysis, VIF and Weights](https://www.phuonglib.com/p/formative-measurement-model-smartpls) |
| `ch37-evaluate-structural-model` | [Evaluating the Structural Model in SmartPLS 4: Collinearity, R² and f²](https://www.phuonglib.com/p/evaluate-structural-model-smartpls) |
| `ch38-plspredict-cvpat` | [Predictive Power in SmartPLS 4: Q²predict, PLSpredict and CVPAT](https://www.phuonglib.com/p/plspredict-cvpat-smartpls) |
| `ch39-bootstrapping-smartpls` | [Bootstrapping in SmartPLS 4: Testing the Significance of the Paths](https://www.phuonglib.com/p/bootstrapping-smartpls-path-significance) |
| `ch40-mediation-analysis-smartpls` | [Mediation Analysis in SmartPLS 4: Indirect Effects and Mediation Types](https://www.phuonglib.com/p/mediation-analysis-smartpls) |
| `ch41-moderation-analysis-smartpls` | [Moderation Analysis in SmartPLS 4: Interaction, f² and Simple Slopes](https://www.phuonglib.com/p/moderation-analysis-smartpls) |
| `ch42-ipma-higher-order-constructs-smartpls` | [IPMA and Higher-Order Constructs in SmartPLS 4](https://www.phuonglib.com/p/ipma-higher-order-constructs-smartpls) |

## License

Data and scripts may be used freely for learning and teaching, with a link back to the series.
