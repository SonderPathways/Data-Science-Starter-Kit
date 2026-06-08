# Section 1: Skip Patterns Handling

## Part of the series "Pathways Project: Technical Guide to Final Data Transformations"

### 1. Context and Purpose

In large-scale demographic surveys like the DHS, **skip patterns** are widely used in questionnaires to ensure efficiency. For example, if a respondent answers "No" to having ever been pregnant, the interviewer will skip all subsequent questions regarding prenatal care, birth delivery locations, and child vaccinations.

In the raw dataset, skipped questions are often assigned specific categorical placeholder values (e.g., "Not applicable", "99", or custom text strings) rather than being left blank. If these placeholders are left untouched during population segmentation or statistical aggregation, they can distort public health metrics by being treated as actual data points.

This pipeline systematically replaces these questionnaire-driven placeholder values with true system-missing values (`NA`). This cleanses the denominator for each metric, ensuring that only individuals who were genuinely eligible to answer a given question are factored into the final public health profile reports.

---

### 2. Step-by-Step Analytical Process

The skip patterns pipeline uses an automated mapping strategy to identify, isolate, and safely clean affected columns:

#### Step 1: Load the Skip Pattern Metadata

The pipeline reads a reference file (`skip_patterns_analysis.csv`) that catalogs known skip interactions across the survey modules.

#### Step 2: Regional and Completeness Filtering

Because survey structures can vary by geography, the pipeline filters the metadata map specifically for rows relevant to the target area:

* It looks for records where the `region` column matches `"Both"` or `"South Nigeria"`.
* It excludes records where the cleaning instructions (`skip_category_south`) are blank or missing (`NA`), focusing only on variables that actively require skip pattern adjustments.

#### Step 3: Iterative Search-and-Replace Processing

The script loops through each entry in the filtered metadata dataframe. For every target variable:

1. **Existence Verification:** It checks if the variable name (`variable_name`) actually exists as a column in the main dataset (`df_edit`). If not found, it gracefully logs a `[SKIP]` notice and continues to the next item to prevent execution crashes.
2. **Column Duplication:** It creates a new variable appending a `_skp_rm` suffix (e.g., `original_name_skp_rm`). This protects raw source data from accidental corruption.
3. **Multi-Category Splitting:** Skip instructions frequently contain multiple placeholder values separated by a semicolon (e.g., `"Not applicable; Don't know"`). The pipeline splits this string dynamically using `strsplit()` and strips away accidental whitespace using `trimws()`.
4. **Targeted NA Masking:** It iterates through each isolated skip value, locating matches within the newly created column and overwriting them with `NA`.
5. **Error Containment:** The block is wrapped inside a `tryCatch()` environment, logging failure messages safely if a variable encounters unexpected formatting anomalies.

---

### 3. Key Code Implementations

Below are the operational code fragments extracted from the R script used to execute skip pattern cleansing.

#### A. Filtering the Skip Pattern Metadata Map

This snippet extracts the target cleaning rules from the reference CSV file.

```r
# Load skip patterns analysis mapping database
skip_patterns <- read.csv("data/skip_patterns_analysis.csv")

# Filter for rows applicable to South Nigeria containing valid skip category rules
skip_vars <- skip_patterns %>%
  dplyr::filter(region %in% c("Both", "South Nigeria")) %>%
  dplyr::filter(!is.na(skip_category_south) & skip_category_south != "")
```

#### B. The Safe Dynamic Cleaning Loop

This loop dynamically creates copy columns and sweeps through the specified string categories to substitute them with R's internal logical NA.

```r
# Iterate through each variable registered with skip patterns
for (i in 1:nrow(skip_vars)) {
  var_name      <- skip_vars$variable_name[i]
  skip_category <- skip_vars$skip_category_south[i]
  short_name    <- skip_vars$short_name[i]

  # Guard rail: Skip processing if column is missing from the dataset
  if (!var_name %in% colnames(df_edit)) {
    cat(sprintf("  [SKIP] Variable '%s' not found in dataset\n", var_name))
    next
  }

  # Establish clean variable name convention
  new_var_name <- paste0(var_name, "_skp_rm")

  tryCatch({
    # Clone original data vector to preserve raw inputs
    df_edit[[new_var_name]] <- df_edit[[var_name]]

    # Parse out multiple skip string targets using the semicolon delimiter
    skip_categories <- strsplit(skip_category, ";")[[1]]
    skip_categories <- trimws(skip_categories)

    # Replace each matched survey skip string category with NA
    for (skip_cat in skip_categories) {
      df_edit[[new_var_name]][df_edit[[new_var_name]] == skip_cat] <- NA
    }

  }, error = function(e) {
    # Fail-safe error logging to console
    cat(sprintf(
      "  [ERROR] Failed to process '%s': %s\n",
      var_name, e$message
    ))
  })
}
```

### C. Post-Transformation Feature Inspection

To verify the execution, analysts can extract unique values across all newly compiled skip-removed columns:

```r
# Locate all columns generated via the skip removal pipeline
skp_cols <- grep("_skp_rm$", names(df_edit), value = TRUE)

# Generate a list displaying the unique values remaining in each column
unique_values <- lapply(df_edit[skp_cols], unique)
print(unique_values)
```

---

### 4. Checklist for Data Analysts

When working through questionnaire skip logic adjustments, remember to complete the following:

* Cross-Check Skip Mappings: Ensure the strings listed in skip_category_south match the exact string spelling, capitalization, and formatting found in the raw survey factors/characters.

* Monitor the Console Output: Look out for any logged [SKIP] or [ERROR] messages when executing the loop to catch mismatched dataset versions.

* Evaluate Denominator Shifts: Run a summary table before and after the cleaning routine. The number of missing entries (NA) in the _skp_rm column should equal the original missing entries plus the sum of all rows matching the skipped categories.
