# Using Segments to Predict Outcomes

This directory collects examples that use Pathways segment membership as predictors in survey-weighted outcome models. Each geography-specific subfolder combines segmentation datasets with priority maternal/child health outcomes, fits `survey`-weighted logistic regressions, and visualizes predicted probabilities by segment. As additional countries are added, include their scripts, outputs, and documentation alongside the existing Northern Nigeria example.

Current example:
- `north_nigeria_pathways` – survey-weighted logistic models predicting home birth, ANC completion, modern contraceptive use, child wasting, and under-five mortality by segment. Includes PDF plots for each outcome.

When contributing new geographies:
1. Create a subfolder named after the geography.
2. Add a README summarizing inputs, outcomes modeled, and output artifacts (plots/tables).
3. Update this parent README with a brief description of the new example for discoverability.

