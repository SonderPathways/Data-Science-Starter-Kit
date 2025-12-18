# U5MR for DHS Solutions

## Overview
This subfolder houses Jess Long’s November 2025 scripts for calculating neonatal, infant, child, and under-five mortality rates by Pathways segments using DHS birth recode (BR) files and the `DHS.rates` package. Two worked examples are included:
- `Calculating U5MR_Kenya.R` – Kenya 2022 DHS (Phase 8) segmentation
- `Calculating U5MR_NN.R` – Northern Nigeria 2018 DHS (Phase 7) segmentation

Both scripts adapt DHS Program sample code (`CM_CHILD.R`) to merge Pathways segment labels onto BR microdata, derive subgroup variables, and compute mortality estimates over 5- and 10-year periods.

## Required inputs
Update the placeholder links below with the secure storage locations for each dataset.

**Kenya example**
- Cleaned Pathways dataset (`Kenya_2022DHS8_1.2.csv`) [`download`](#)
- DHS birth recode (`KEBR8CFL.DTA`) [`download`](#)

**Northern Nigeria example**
- Cleaned Pathways dataset (`North_Nigeria_2018DHS7_1.0.csv`) [`download`](#)
- DHS birth recode (`NGBR7BFL.DTA`) [`download`](#)

All datasets must include DHS identifiers (`caseid`, `v021`, `v022`, `v024`, `v025`, `v005`, `v008`, `v011`, `b3`, `b7`, `v106`, `v190`), Pathways segment names, and strata definitions.

## Prerequisites
- R ≥ 4.0
- Packages: `haven`, `naniar`, `dplyr`, `tidyr`, `survey`, `sjlabelled`, `data.table`, `expss`, `stringr`, `DHS.rates`

Install missing packages with:

```r
install.packages(c(
  "haven","naniar","dplyr","tidyr","survey","sjlabelled",
  "data.table","expss","stringr","DHS.rates"
))
```

## Workflow summary
1. **Load Pathways and DHS BR files** – reads the country-specific segmentation CSV and the DHS birth recode. Cleans `caseid` when needed to ensure merges succeed.
2. **Merge segment labels** – retains `caseid`, `segment_name`, and `strata` from Pathways, then `inner_join`s onto the BR file so each birth record inherits its segment.
3. **Create subgroup variables** – reproduces DHS indicator recodes for child sex, mother’s age at birth, birth order, preceding birth interval, and birth size (with missing handling).
4. **Define analysis dataset** – keeps the core DHS fields required by `DHS.rates::chmort`.
5. **Compute mortality rates** – calls `chmort()` for the overall sample and for specific classes (segment, region `v024`, rural/urban `v025`/`strata`) over 5-year (60 month) and 10-year (120 month) periods. Optional jackknife (`JK = "Yes"`) adds SEs/CIs.
6. **Interpret results** – the resulting data frames contain `R` (rate per 1,000 live births), `N` (unweighted births), and `WN` (weighted births) for each subgroup and period.

## Running an example
1. Download the required Pathways and DHS BR files to the file paths referenced near the top of the script or adjust the `file_path`/`dhsdata_path` variables.
2. From this directory, execute:
   ```bash
   Rscript "Calculating U5MR_Kenya.R"
   ```
   or substitute the Nigeria script.
3. Review the console outputs (`resn1`, `kemort_segment5`, etc.) and save them as needed (e.g., write CSVs or RDS files).

## Notes
- Ensure you have DHS Program permission to download BR files.
- When adapting to other countries, replace the file paths, segmentation CSV, and check whether `caseid` requires trimming/reformatting before the merge.
- Keep the author attribution (Jess Long) when sharing or modifying these scripts.
