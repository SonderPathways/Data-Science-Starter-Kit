# Northern Nigeria Pathways – Segment-Based Outcome Predictions

## Overview
`analysis.R` applies `survey`-weighted logistic regression to test how well Northern Nigeria Pathways segments predict key maternal and child health outcomes. For each indicator, the script:
1. Filters respondents with non-missing outcomes.
2. Declares the survey design using `PSUclean` and the `weight` variable.
3. Fits `svyglm(outcome ~ class, family = quasibinomial())`.
4. Computes predictive accuracy (0.5 threshold) and segment-level predicted probabilities with 95% confidence intervals using `svyby`.
5. Plots the estimated probabilities by segment.

Modeled outcomes:
- Home birth (`hb.sum.yn`)
- ANC fewer than 4 visits (`anc.4plus`, modeled as probability of <4 visits)
- Modern contraception non-use (`fp.current.any`)
- Any child wasting (`her.wasting`)
- Under-five mortality experience (`death.u5`)

## Required inputs
- `Nigeria_North_2022Pathways1_1.3.csv` – Pathways survey dataset with segment assignments, survey weights, PSU identifiers, and all outcome variables. [`download`](#)

Place the CSV in this folder and update the placeholder link when a permanent storage location exists.

## Prerequisites
- R ≥ 4.0
- Packages: `survey`, `dplyr`, `ggplot2`

Install missing packages with:

```r
install.packages(c("survey","dplyr","ggplot2"))
```

## Running the analysis
1. Ensure the Pathways CSV is present.
2. From this directory, run:
   ```bash
   Rscript analysis.R
   ```
3. Inspect console output for model summaries and accuracy. The script renders five plots to your active graphics device.

## Output artifacts
PDF plots generated from the script are stored in `pathways_NN_plots/`:
- `ANC.pdf` – probability of fewer than four ANC visits by segment.
- `home_birth.pdf` – probability of delivering at home by segment.
- `mCP.pdf` – probability of not using modern contraception by segment.
- `under5_mort.pdf` – probability of reporting an under-five child death by segment.
- `wasting.pdf` – probability of any child wasting by segment.

Update these files (or add new ones) when re-running the script; link replacements can target your preferred document repository if needed.

## Notes
- Adjust the `svydesign` block if you model DHS merged data instead of Pathways-only (`v021/v023/wt` lines are provided as comments).
- Add `ggsave()` calls after each `ggplot` block if you prefer automatic export instead of relying on the RStudio plot pane.
- When extending to other outcomes/geographies, follow this folder structure so the parent README can reference your work consistently.
