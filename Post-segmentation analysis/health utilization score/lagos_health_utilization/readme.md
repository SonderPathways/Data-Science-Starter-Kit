# Lagos Health Utilization Score (Lagos, Nigeria)

## Overview
This example reproduces the maternal and child health service utilization score that Sonder used when prioritizing Lagos segments from the 2013 Demographic and Health Survey (DHS). The script `lagos_health_utilization.R` loads pre-generated segmentation assignments, links them to DHS respondents, derives zero-dose status for children 10–23 months, recodes care-seeking indicators, and produces weighted utilization summaries by refined Lagos segments.

## Required inputs
- Nigeria 2013 DHS child recode (`NGBR6AFL.DTA`) – place in `data/NGBR6ADT/` & [download](https://drive.google.com/file/d/15m6JmGKw6e_6f2mj_UIuJpgFK3Bj91Jt/view?usp=drive_link).
- Nigeria 2013 DHS individual recode (`NGIR6AFL.DTA`) – place in `data/NGIR6ADT/` & [download](https://drive.google.com/file/d/15m6JmGKw6e_6f2mj_UIuJpgFK3Bj91Jt/view?usp=drive_link).
- Nigeria 2013 DHS household recode (`NGHR6AFL.DTA`) – place in `data/NGHR6ADT/` & [download](https://drive.google.com/file/d/15m6JmGKw6e_6f2mj_UIuJpgFK3Bj91Jt/view?usp=drive_link). *(Currently loaded but not used directly; keep for completeness.)*
- Pathways segment factors (`DHS Pathways interim segments & factors.RDat`) – place in `clean_data_files/` & [download](https://drive.google.com/file/d/15m6JmGKw6e_6f2mj_UIuJpgFK3Bj91Jt/view?usp=drive_link).

Update the placeholder links with the secure storage locations you use for DHS data.

## Prerequisites
- R ≥ 4.0 with the packages declared at the top of the script (notably `data.table`, `dplyr`, `survey`, `haven`, `magrittr`, `stringr`, `ggplot2`, `corrplot`, `doParallel`, `psych`, `vtable`, `tm`, and supporting tidyverse packages).
- DHS datasets licensed for your organization.

To install the required packages once, run:

```r
install.packages(c(
  "data.table","dplyr","survey","haven","magrittr","stringr","ggplot2",
  "gridExtra","reshape","survival","tidyr","plyr","tm","labelled",
  "forcats","doParallel","foreign","psych","vtable","corrplot"
))
```

## Workflow summary
1. **Segment linkage** – loads Pathways segments, rebuilds DHS `caseid` (cluster + household + line number), and keeps Lagos-relevant segments.
2. **Child immunization status** – reads the child recode, computes DPT1–3 receipt, defines a zero-dose flag (`dpt0`) for 10–23 month-olds who never received DPT, and retains living children.
3. **Care-seeking indicators** – recodes diarrhea/fever treatment, ANC attendance, place of delivery, postnatal care, family planning ever-use, and contact with facilities/CHWs.
4. **Health facility delivery history** – aggregates all available births per woman in `NGIR6AFL` to determine whether she has ever delivered at a facility.
5. **Survey-weighted scoring** – applies DHS weights and `survey` design objects to compute the count and percent of women using each service within each segment, then averages the utilization percentages when needed.
6. **Outputs** – writes segment-by-service detail (`heath_utilization_by_service_lagos.csv`) and simplified averages (`heath_utilization_average_lagos.csv`) to the project root.

## Running the script
1. Download the required DHS and segmentation files and place them in the directories noted above.
2. Open a terminal at `Post-segmentation analysis/health utilization score/lagos_health_utilization/`.
3. Execute:
   ```bash
   Rscript lagos_health_utilization.R
   ```
4. The CSV outputs appear in the same folder once processing completes.

## Output files
- `heath_utilization_by_service_lagos.csv` – weighted counts and percentages for each combination of refined segment, health service, and service status.
- `heath_utilization_average_lagos.csv` – average utilization percentage for each segment among women using the service (`status == 1`).

Both outputs exclude NA records before summarizing and can be joined back to original segments for downstream reporting.

