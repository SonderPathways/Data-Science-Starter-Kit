# Section 3: Complex Inversions & Aggregation Logic

## Part of the series "Pathways Project: Technical Guide to Final Data Transformations"

### 1. Context and Purpose

Unlike simple binary inversions, evaluating compound public health conditions like **complete child immunization schedules** or **healthcare facility utilization** requires complex, multi-layered logic.

In the DHS framework, single indicators are often spread across separate survey modules or split into multiple individual variables. For example:

* **Vaccination tracking** requires looking at specific source variables (vaccination card dates, card marks, or mother's recall) across multiple doses (e.g., DPT 1, 2, and 3; Polio 1, 2, and 3).
* **Age schedules** must be accounted for. Public health metrics dictate that a child should only be penalized for missing a vaccine if they have reached the age threshold where that vaccine is mandated by the schedule (e.g., Measles at 9 or 12+ months).
* **Unit of Analysis Shifts:** Survey datasets are split into child-level metrics (the `KR` or `BR` files) but need to be reported as aggregate maternal/household vulnerability profiles (the individual woman/mother level in the `IR` file).

This pipeline standardizes these intricate conditions into clean, multi-variable composite rules and aggregates individual child records up to the mother level, ensuring that `1` consistently reflects a completely protected state or a positive health utilization outcome.

---

### 2. Step-by-Step Analytical Process

This complex transformation pipeline operates in three distinct technical phases:

#### Phase 1: Child-Level Multi-Dose Harmonization (KR File)

For individual vaccine antigens (DPT, Polio, Pneumococcal, Measles, BCG, Yellow Fever, Meningitis):

1. **Source Concatenation:** The script scans specific DHS variables (e.g., `h3`, `h5`, `h7` for DPT) and categorizes positive verification ("vaccination date on card", "vaccination marked on card", "reported by mother") as `1`, and negative responses ("no", "don't know") as `0`.
2. **Dose Summation:** Individual doses are summed together to create a cumulative score (e.g., `dptsum = dpt1 + dpt2 + dpt3`).
3. **Full Course Validation:** If the sum matches the exact multi-dose requirement (e.g., `dptsum == 3`), the child is marked as fully protected (`1`); otherwise, they are marked as `0` (while preserving `NA` if the sum is missing).

#### Phase 2: Applying Age-Dependent Schedule Masks

To ensure that metrics are fair, children are filtered based on their precise age in months (`b19`).

* If a child is below the age threshold for a specific immunization schedule, their metric is forced to `NA_real_` so they are excluded from the denominator.
* If they meet or exceed the age threshold, they receive their actual evaluated vaccination status.

#### Phase 3: Aggregation to Woman-Level Measures (`caseid`)

Because a single mother (`caseid`) can have multiple children in the survey records, individual child entries must be consolidated into a unique maternal profile:

1. **Eligibility Check:** The script calculates the total number of eligible children a woman has for a specific health indicator (e.g., `n_eligible_basic = sum(!is.na(basic.antigen.full.12m))`).
2. **"All-or-Nothing" Inversion Rule (`case_when` / `all`):** * If a mother has no eligible children, her profile is assigned an `NA`.
   * If **all** of her eligible children are fully vaccinated, she receives a successful score of `1` (indicating a desired outcome profile).
   * If even a single child has missed their required schedule, the mother is flagged with a `0`.
3. **Maternal Join:** These final unified rows are joined directly back into the main master dataset (`df_edit`) using `caseid` as the relational key.

---

### 3. Key Code Implementations

#### A. Harmonizing Multi-Dose Antigens & Applying Age-Schedules

This code demonstrates how individual child responses are combined, summed, and masked based on age thresholds (`b19`).

```r
# Synthesize multi-dose DPT verification sources
KR <- KR %>%
  dplyr::mutate(
    dpt1 = dplyr::case_when(h3 %in% c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h3 %in% c("no","don't know") ~ 0),
    dpt2 = dplyr::case_when(h5 %in% c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h5 %in% c("no","don't know") ~ 0),
    dpt3 = dplyr::case_when(h7 %in% c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h7 %in% c("no","don't know") ~ 0)
  ) %>%
  dplyr::mutate(dptsum = dpt1 + dpt2 + dpt3) %>%
  dplyr::mutate(dpt.all = dplyr::case_when(is.na(dptsum) ~ NA, dptsum == 3 ~ 1, TRUE ~ 0))

# Apply age-dependent schedules (e.g., basic antigen full course at 12+ months)
KR <- KR %>%
  dplyr::mutate(
    basic.antigen.full.12m = dplyr::case_when(
      b19 < 12 ~ NA_real_,
      b19 >= 12 & bcg.all == 1 & dpt.all == 1 & polio.all == 1 & measles1 == 1 ~ 1,
      b19 >= 12 ~ 0
    )
  )
```

#### B. Aggregating Child Records to Unique Mother Profiles

This critical step collapses the granular child data into a unified vector per woman, applying the strict baseline rule that a household is only fully secure if all eligible children are covered.

```r
# Compress child-level (KR) data into woman-level summaries
kr.out <- KR %>%
  dplyr::group_by(caseid) %>%
  dplyr::summarize(
    # Count how many children meet the age eligibility baseline
    n_eligible_basic = sum(!is.na(basic.antigen.full.12m)),
    
    # Apply woman-level outcome determination
    basic.antigen.full.12m.yn_inv = dplyr::case_when(
      n_eligible_basic == 0 ~ NA_real_,
      all(basic.antigen.full.12m[!is.na(basic.antigen.full.12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    .groups = "drop"
  )

# Keep only the ID and final transformed inverted features
kr.out <- kr.out %>%
  dplyr::select(caseid, dplyr::ends_with("_inv"))
```

#### C. Final Multi-Module Master Integration

Once individual modules (ir.out, kr.out, br.out) are structured identically at the caseid level, they are woven back into the target analytics dataset.

```r
# Merge distinct structural modules via relational ID
outcomes_inv <- ir.out %>%
  base::merge(kr.out, by = "caseid", all.x = TRUE) %>%
  base::merge(br.out, by = "caseid", all.x = TRUE)

# Left join the compiled features back to the main data frame
df_edit <- df_edit %>%
  dplyr::left_join(outcomes_inv, by = "caseid")
````

__

### 4. Checklist for Data Analysts

* Confirm Categorical Variable Text Alignment: Check that the string expressions inside case_when() (such as "reported by mother") precisely match the factor labels or character configurations of the raw data files.

* Validate Age Variable Units: Ensure that variable b19 (or its equivalent) is explicitly calculated in months rather than days or years before running the age-schedule masks.

* Handle Missing Values in all() Functions: Inside the summarize() step, always pass !is.na(variable) as an index to the all() function (e.g., all(variable[!is.na(variable)] == 1)). Failing to drop missing subsets inside all() will cause the entire maternal summary to render as NA if even one child has missing data.

* Verify Granularity after Joins: Check the row count of df_edit before and after executing the final left_join(). The row count should remain exactly identical. If the row count increases, it means the aggregation files still contain duplicate caseid rows.
