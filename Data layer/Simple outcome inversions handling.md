# Section 2: Simple Outcome Inversions Handling

## Part of the series "Pathways Project: Technical Guide to Final Data Transformations"

### 1. Context and Purpose

In public health data analysis, indicators are gathered from various modules of large-scale surveys like the Demographic and Health Surveys (DHS). Depending on how a question is framed in the original questionnaire, a value of `1` might represent a negative health state (e.g., "Child has anemia") or a positive health state (e.g., "Child was vaccinated").

To deliver clean, intuitive, and unambiguous dashboards or reports for non-technical stakeholders (such as public health policymakers or field designers), it is crucial to standardize the direction of these indicators. The **Pathways Project** standardizes outcomes so that a uniform value alignment is achieved across metrics—typically ensuring that `1` consistently represents a favorable or "desired" health outcome, making it immediately interpretable.

This section automates the process of flipping binary indicators ($0$ to $1$, and $1$ to $0$) for a pre-defined list of variables that have been flagged as requiring a directional adjustment.

---

### 2. Step-by-Step Analytical Process

The simple outcome inversion pipeline follows a programmatic workflow to dynamically load, filter, transform, and validate variables. Here is the step-by-step breakdown:

#### Step 1: Load the Reference Mapping File

Before modifying any data, the pipeline reads an external Excel mapping file (`outcomes_to_flip_recode.xlsx`) containing metadata about which variables require transformation.

* It targets a specific geographic/survey sheet (e.g., `"Southern Nigeria"`).

#### Step 2: Extract Target Inversion Variables

The mapping file contains flags determining how variables should be handled. For a simple inversion:

* The pipeline filters for records where `flip == 1` (indicating that the variable needs to be inverted).
* It ensures `recode == 0` (indicating that it only requires a simple binary flip rather than a complex multi-categorical recoding logic).
* A vector of these specific variable names (`outcome_variable`) is pulled into memory.

#### Step 3: Vectorized Inversion Transformation

Using a vectorized framework (`dplyr::mutate` combined with `across`), the script loops over all identified variables in the main dataset (`df_edit`). For each targeted variable:

* If the original value is `1`, it is transformed to `0`.
* If the original value is `0`, it is transformed to `1`.
* Any other values (such as system missing values or `NA`) are explicitly preserved as `NA_integer_`.
* **Naming Convention:** To ensure traceability and prevent overwriting raw source columns, the transformed variables are saved with an `_inv` suffix (e.g., `original_variable_name_inv`).

#### Step 4: Quality Control & Visual Validation

To guarantee data integrity, the pipeline automatically generates cross-tabulations (`table()`) comparing the original column against the new `_inv` column. Analysts must review these matrices to confirm a perfect diagonal inversion and verify that missing data counts (`NA`) match exactly.

---

### 3. Key Code Implementations

Below are the key code blocks adapted from the pipeline to demonstrate how this is executed in R.

#### A. Filtering the Metadata Map

This snippet shows how the pipeline dynamically extracts only the columns that require a simple binary inversion.

```r
# Load outcomes inversions analysis metadata sheet
inv_outcomes <- read_excel("data/outcomes_to_flip_recode.xlsx", sheet = "Southern Nigeria")

# Filter and pull variables requiring a simple binary flip (flip is 1, recode is 0)
inv_outcomes_vars <- inv_outcomes %>%
  dplyr::filter(flip == 1 & recode == 0) %>%
  dplyr::pull(outcome_variable)

# Display the variables selected for inversion
print(inv_outcomes_vars)
````

#### B. Executing the Vectorized Inversion

This block utilizes dplyr::across() and all_of() to securely modify only the columns present in the inv_outcomes_vars vector across the entire dataset.

```r
# Apply the binary inversion transformation across all selected columns
df_edit <- df_edit %>%
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(inv_outcomes_vars),
      ~ dplyr::if_else(. == 1, 0L,
                dplyr::if_else(. == 0, 1L, NA_integer_)),
      .names = "{.col}_inv"
    )
  )
````

#### C. Automated Validation and Quality Assurance

This looping structure guarantees that every single transformed variable is audited by printing a contingency table directly to the console.

```r
# Isolate all newly created inversion columns
inv_cols <- grep("_inv$", names(df_edit), value = TRUE)

# Generate cross-tabulations to verify the structural inversion
for (v in inv_cols) {
  # Deduce the original variable name by removing the suffix
  orig <- sub("_inv$", "", v)
  
  cat("\n=== Validation: ", v, " vs ", orig, " ===\n")
  
  # Print matrix including missing values
  print(
    table(
      df_edit[[v]],
      df_edit[[orig]],
      useNA = "ifany"
    )
  )
}
```

---

### 4. Checklist for Data Analysts

When onboarding a new survey dataset or region into the Pathways segmentation pipeline, use this checklist to execute simple outcome inversions:

* Verify Metadata Sheets: Ensure that outcomes_to_flip_recode.xlsx contains the exact variable names present in your raw survey dataset.
* Check Column Classes: Confirm that the variables targeted for simple inversion are stored as numeric or integer types containing 0 and 1.
* Review Validation Tables: When running the verification loop, ensure that your cross-tabulation looks exactly like this:

    ```Plaintext

             0    1
        0    0    X
        1    Y    0
    ```

    (Where X is the original number of 1s, and Y is the original number of 0s. There should be zero values on the main diagonal).

* Inspect Missingness: Confirm that the total number of NA cases in the original column exactly matches the NA count in the _inv column.
