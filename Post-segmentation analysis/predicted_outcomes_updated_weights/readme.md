# Predicted Outcomes With Updated Weights (Senegal)

## Overview
`analysis_SM.R` demonstrates how to evaluate predicted outcomes for the Senegal Pathways–DHS merge using updated survey weights. The script fits a survey-weighted logistic regression to estimate the probability that women in each segment are not currently using a modern family planning method (`nofp.mod.now`), computes accuracy from the weighted predictions, and visualizes segment-level predicted probabilities with confidence intervals.

## Required inputs
- `merged_pathways_dhs.csv` – merged dataset containing Pathways segment assignments and DHS indicators for Senegal (place in the same folder). Update this placeholder when you finalize the storage location: [`download`](https://drive.google.com/file/d/1oLt57TxGeyjFEMibq6UO350c8EXlBJzm/view?usp=drive_link).

The CSV must include:
- Outcome column `nofp.mod.now` (binary)
- Segment identifier `segment_name` (or `class`, depending on final column naming)
- Survey weights `wt`
- PSU and strata identifiers `v021.x`, `v023.x`

## Prerequisites
- R ≥ 4.0
- Packages: `survey`, `dplyr`, `ggplot2`

Install missing packages with:

```r
install.packages(c("survey","dplyr","ggplot2"))
```

## Workflow summary
1. **Load data** – reads `merged_pathways_dhs.csv` and removes records with missing outcome values.
2. **Declare survey design** – sets up a `survey::svydesign` using DHS cluster (`v021.x`), strata (`v023.x`), and weight (`wt`) variables.
3. **Model the outcome** – fits a survey-weighted logistic regression (`svyglm`) of `nofp.mod.now` on `segment_name`.
4. **Assess accuracy** – derives predicted probabilities, converts them to binary predictions via 0.5 threshold, and uses `svymean` to compute weighted classification accuracy (stored as `accuracy`).
5. **Generate predictions per segment** – predicts on the link scale to extract standard errors, back-transforms to probabilities, attaches 95% confidence intervals, and aggregates by segment with `svyby`.
6. **Plot** – produces a horizontal dot plot of mean predicted probabilities with error bars and labels, ordering segments according to `seg_order` and including the overall accuracy in the subtitle.

## Running the script
1. Place `merged_pathways_dhs.csv` in this directory and ensure it has the variables listed above.
2. Open a terminal at `Post-segmentation analysis/predicted_outcomes_updated_weights/`.
3. Execute:
   ```bash
   Rscript analysis_SM.R
   ```
4. Review the console output for the model summary and accuracy; the plot renders to your active graphics device (RStudio plot pane or default system device).

## Output
- Console summary from `svyglm` and `svymean`.
- A visualization of predicted probabilities by segment (rendered via `ggplot2`). Save it manually if needed (e.g., wrap the plotting block with `ggsave()`).

## Notes
- `segment_name` vs. `class`: The sample plot groups by `seg.name` but the `svyby` call groups by `class`. Ensure the merged dataset has both or adjust the code to use one consistent identifier.
- Update the placeholder `#` link once the merged Senegal dataset is accessible in your cloud storage.
