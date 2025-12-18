# Nigeria Pathways Survey Health Utilization Scores

## Overview
`15_NN_health_utilization.Rmd` reproduces the first Sonder implementation of the maternal and child health service utilization index using the Nigeria Pathways (PWS) segmentation survey instead of DHS microdata. The notebook links latent class assignments to the raw survey responses, derives proxies for key maternal/child care behaviors, and produces weighted utilization summaries for both segments (`class`) and broader consumer profiles. Because PWS v1.0 lacked certain DHS questions (e.g., postnatal care), the script documents every adjustment made to align the score definition with the DHS-based version.

## Required inputs
Place the following files under the paths expected by the R Markdown document and update the placeholder links once a new storage location is finalized:

- `LCA data/Final data named/NN_all.class.rds` – combined Nigeria segment assignments [`download`](#)
- `LCA data/Final data named/NN_rural.class.rds` – rural subset [`download`](#)
- `LCA data/Final data named/NN_urban.class.rds` – urban subset [`download`](#)
- `Pathways_Nigeria_merged.sav` – raw Pathways Nigeria survey with weights and questionnaire variables [`download`](#)

All datasets must include segmentation identifiers (`class`), cleaned PSU/strata/weight fields, and questionnaire variables such as `C17`, `fp.*`, `A05`, `T_A06_1`, `hb.yn`, `C24`, `C25`, and `her.ill.doctor`.

## Prerequisites
- R ≥ 4.0
- R packages loaded via `pacman::p_load(...)` at the top of the notebook (notably `data.table`, `dplyr`, `survey`, `haven`, `stringr`, `magrittr`, `writexl`, `ggplot2`, `psych`, `vtable`, `corrplot`, `reshape`, `gridExtra`, `tm`, `forcats`, `plyr`, `tidyr`, `survival`, `doParallel`, `labelled`, `foreign`)
- Directory `health utilization score files/` for outputs (create it if it does not already exist)

## Workflow summary
1. **Load segmentation objects** – imports the all sample plus rural/urban RDS files produced by the Pathways LCA workflow.
2. **Merge with raw PWS survey** – reads `Pathways_Nigeria_merged.sav`, filters for the interview type of interest, trims blanks, and rebuilds `caseid` to align each respondent’s class membership with detailed questionnaire responses (including `A05`, `T_A06_1`).
3. **Derive utilization indicators**  
   - ANC visits (`anc.num`, `anyanc`, `anc.4plus`) using `C17` and mean imputation for “don’t know”.  
   - Family planning ever-use (`fp.mod.ever`, `fp.ever`) combining current and previous use.  
   - Community health worker availability proxy (`hc.area`) leveraging `A05`.  
   - Home delivery history (`hb.yn`), facility delivery (`hf_deliv`).  
   - Care-seeking for fever/respiratory and diarrhea using child illness (`C24_*`) and provider (`C25_*`) items.  
   - Woman’s own care-seeking when ill (`her.ill.doctor`).  
   - Notes that PNC cannot be scored because the PWS instrument omitted those questions.
4. **Compute utilization score** – sums the binary indicators (`anyanc + hc.area + fp.mod.ever + diarr + fever + her.ill.doctor`) and adds one point when the respondent has never delivered at home; respondents missing delivery data are excluded from the score.
5. **Survey-weighted tabulations** – builds a `survey::svydesign` object using `PSUclean`, `URBAN_RURA`, and `weight`, then calculates weighted counts/percentages for each indicator by segment (`class`). A helper removes NA rows from denominators.
6. **Profile-level rollups** – maps segments to broader profiles (Worried Potentials, Intending Support Seekers, Aware Reactives, Unreached Fatalists) and repeats the survey-weighted tabulations.
7. **Outputs** – writes an Excel workbook at `health utilization score files/[Segment]health_utilization_score.xlsx` containing:  
   - Segment-level detailed status (with and without the community health worker indicator)  
   - Segment-level average utilization percentages  
   - Profile-level detailed status (with and without the community health worker indicator)  
   - Profile-level average utilization percentages  
   Use the parallel script block at the bottom if you also want CSV exports for each table.

## Running the analysis
1. Download the four required data sources to the paths above and ensure `health utilization score files/` exists.
2. Open the project root (`Post-segmentation analysis/health utilization score/NN_PWS_health_utilization/`) in RStudio or run from the terminal.
3. Render the notebook to your preferred format (HTML/Word/PDF) with:
   ```bash
   Rscript -e "rmarkdown::render('15_NN_health_utilization.Rmd')"
   ```
   or knit inside RStudio.
4. The Excel workbook will appear inside `health utilization score files/`. Review the logs/tables in the knitted document for sanity checks on each indicator.

## Notes on methodology differences vs. DHS
- The Pathways survey lacks postnatal care modules; the health utilization score replaces that component with “woman goes to a health facility when ill.”
- Care-seeking for child diarrhea and fever uses three-month recall proxies instead of DHS’s two-week modules.
- Community health worker engagement is approximated by perceived access rather than the DHS “visited by/visited facility” items. Two sets of outputs (with vs. without the CHW proxy) are generated to mirror DHS comparability.
- Make sure downstream consumers document these substitutions whenever PWS-derived scores are compared to DHS-based metrics.

