# Validating Qualitative Hypotheses With Quantitative Data (Senegal)

## Overview
`Senegal_DHS_Qual-Quant.Rmd` captures Lang Gao’s workflow (June 2025) for translating qualitative hypotheses from the Senegal FP project into testable, survey-weighted analyses using DHS and Pathways segmentation data. The notebook sets up merged datasets (rural, urban, full sample), calculates indicators such as zero-dose children, and runs targeted tabulations or models to confirm/refute insights from qualitative fieldwork. Some chunks are marked `eval = FALSE` because they reference intermediate data products or exploratory investigations; review the inline notes for interpretation guidance.

## Required inputs
Update the placeholder links with your actual storage locations.
- Segmentation RDS exports (`SEN.rural.all.class.rds`, `SEN.urban.all.class.rds`, `Senegal.all.class.rds`) [`download`](#)
- DHS household recode files (`SNHR81FL.DTA`, `SNHR8BFL.DTA`) [`download`](#)
- DHS individual recode files (`SNIR81FL.DTA`, `SNIR8BFL.DTA`) [`download`](#)
- DHS child recode files (`SNKR81FL.DTA`, `SNKR8BFL.DTA`) [`download`](#)

## Prerequisites
- R ≥ 4.0
- Packages loaded via `pacman::p_load(...)` in the setup chunk (tidyverse, survey, ggplot2, ggalluvial, ggnetwork tools, modeling packages like `lavaan`, `lme4`, `nnet`, tree/forest packages, etc.). Ensure all dependencies are installed before knitting.
- Directory permissions to read/write merged RDS files (`Senegal_merged.rds`, etc.).

## Workflow summary
1. **Setup and package loading** – configures knitr options, working directory, and loads plotting/modeling libraries.
2. **Reference coding** – documents how reasons for non-use or barriers are categorized, aiding interpretation of downstream tables.
3. **Data assembly (eval=FALSE blocks)** – reads rural/urban/full segmentation RDS files, DHS household/individual/child recodes, harmonizes survey identifiers, computes zero-dose indicators, and merges everything into combined datasets saved as RDS.
4. **Analytical sections** – subsequent sections (not displayed in this excerpt) connect qualitative hypotheses to survey-driven evidence, producing tables, plots, or regression outputs for discussion with the research team. Many chunks include inline commentary explaining how to interpret the results.

## Running the analysis
1. Download the required DHS and segmentation files to the paths referenced in the R Markdown (or parameterize the document to accept different paths).
2. Open RStudio at `Post-segmentation analysis/Validate hypotheses from qual/`.
3. Knit the document:
   ```bash
   Rscript -e "rmarkdown::render('Senegal_DHS_Qual-Quant.Rmd')"
   ```
4. Use the rendered HTML/PDF/Word output to review quantitative validation metrics alongside qualitative findings.

## Notes
- Maintain the authorship attribution (Lang Gao) when sharing the document or adapting it to other geographies.
- Chunks tagged with `eval=FALSE` may require updating file paths or removing once the merged datasets are available locally.
- Replace the placeholder download links with actual locations (e.g., OpenHexa datasets, secure cloud storage) before sharing the README externally.
