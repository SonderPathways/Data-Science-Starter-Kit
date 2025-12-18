# Segment Population Estimates

## Overview
This folder contains Jess Long’s guidance on estimating Pathways segment population totals for DHS-based solutions. Use the R Markdown walkthrough (`Estimating segment pops.rmd`) alongside the PDF guide (`Guidance Document_Estimating Segment Pops.pdf`) to replicate the workflow for any country. The workflow combines UN World Population Prospects (WPP) totals with DHS microdata and Pathways weights to derive national and segment-level counts of Pathways-eligible women of reproductive age (WRA).

## Included resources
- `Estimating segment pops.rmd` – step-by-step R Markdown authored by Jess Long (2025-11-07) demonstrating the Kenya 2022 DHS example.
- `Guidance Document_Estimating Segment Pops.pdf` – narrative guidance covering the same process; keep the authorship attribution when sharing externally.

## Required inputs
The R Markdown example reads several external files that are not stored in this repository. Update the placeholder links below when you have the definitive storage locations:
- UN WPP female population of reproductive age CSV for the target country/year [`download`](#)
- DHS IR (`KEIR8CFL.DTA` in the example) and BR (`KEBR8CFL.DTA`) files [`download`](#)
- Cleaned Pathways segmentation dataset for the chosen solution, including weights/segments (`Kenya_2022DHS8_1.2.csv` in the example) [`download`](#)
- Segmentation Solutions Log in Notion (reference only; confirm you have access)

## Workflow summary
1. **Collect WRA totals** – download the female population of reproductive age from UN WPP for the relevant country/year and read the CSV into R to get the national WRA count.
2. **Determine Pathways eligibility share** – consult the Segmentation Solutions Log to understand inclusion criteria (e.g., women with a child under five). Use the DHS IR + BR files to subset women meeting those criteria and compute the proportion of all WRA who are Pathways-eligible.
3. **Estimate total eligible WRA** – multiply the WPP WRA total by the eligibility proportion to estimate how many women nationally fall into the Pathways universe. If eligibility criteria are unclear, you can instead use the total number of records in the Pathways dataset.
4. **Allocate to segments** – load the Pathways segmentation dataset, declare the `survey` design (`svydesign` using DHS cluster/strata/weights), and compute segment-level weighted percentages (`svytable`). Multiply each segment’s share by the total eligible WRA to obtain segment population counts.
5. **Document assumptions** – note any discrepancies between WPP/DHS totals and Pathways weights, and cite the limitations section from the Rmd/PDF (e.g., WPP provides modeled estimates, eligibility criteria may be incomplete).

## Running the example R Markdown
1. Download the WPP CSV, DHS files, and Pathways dataset to local paths referenced in the Rmd or parameterize the document to accept file paths.
2. Open RStudio at `Post-segmentation analysis/Segment population estimates/`.
3. Knit `Estimating segment pops.rmd` to PDF:
   ```bash
   Rscript -e "rmarkdown::render('Estimating segment pops.rmd')"
   ```
4. Follow the prompts in the rendered document/PDF to adapt the methodology to other countries or segmentation solutions.

## Notes
- Maintain the authorship attribution to Jess Long when reusing or adapting the guidance.
- Replace the `#` placeholder links with the actual file locations once data sharing arrangements are finalized.
- Ensure you have DHS data access rights before downloading IR/BR files.
