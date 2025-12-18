# Random Forest Feature Discovery (Nigeria Pathways)

## Overview
`predictor_importance_random_forest.R` builds a random forest classifier to discover which Pathways survey variables are most predictive of household delivery behavior (`hb.sum.yn`) within the Nigeria combined segmentation sample. The script ingests the all-sample RDS and a curated list of candidate predictors, trains a random forest with 500 trees, evaluates its performance, and visualizes feature importance using the Mean Decrease in Gini index.

## Required inputs
- `NN_all.class.rds` – merged Nigeria Pathways dataset containing `hb.sum.yn` and all potential predictors. [`download`](#)
- `vars.csv` – CSV containing a column `varnames` listing the predictor variables to include. [`download`](#)

Place both files in this directory and update the placeholder links when the canonical storage paths are available.

## Prerequisites
- R ≥ 4.0
- Packages: `randomForest`, `caret`, `ggplot2`, `dplyr`

Install missing packages with:

```r
install.packages(c("randomForest","caret","ggplot2","dplyr"))
```

## Workflow summary
1. **Load data** – reads the Pathways RDS and the CSV specifying which columns to keep; combines them with the binary outcome `hb.sum.yn`.
2. **Factor conversion** – converts all predictors and the target to factors to satisfy `randomForest`’s classification requirements.
3. **Missing data handling** – reports NA percentages per column, then drops any rows with missing values (`complete.cases`).
4. **Train/test split** – uses `caret::createDataPartition` to create an 80/20 split stratified by `hb.sum.yn`.
5. **Model training** – fits a random forest with 500 trees (`importance = TRUE`) on the training data.
6. **Evaluation** – predicts on the test set and prints the confusion matrix via `caret::confusionMatrix`.
7. **Feature importance** – extracts the Mean Decrease in Gini per predictor and produces a horizontal bar chart highlighting the highest-impact variables.

## Running the script
1. Ensure `NN_all.class.rds` and `vars.csv` are in this folder.
2. From `Post-segmentation analysis/random_forest_feature_discovery/`, run:
   ```bash
   Rscript predictor_importance_random_forest.R
   ```
3. Check the console output for the confusion matrix and inspect the variable-importance plot in your active graphics device. Add a `ggsave()` call if you need to persist the chart.

## Notes
- The current workflow drops all rows with NA values; consider imputing or restricting the predictor list if too many observations are removed.
- Adjust `ntree`, `mtry`, or class weights if you need a more tuned model for downstream use cases.
- Update the placeholder links when the Pathways data and `vars.csv` live in their permanent storage location.
