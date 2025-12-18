# Under-Five Mortality Rate (U5MR) Analyses

This directory aggregates workflows for estimating under-five mortality rates by Pathways segments. Each subfolder contains a reproducible example that merges DHS birth recode microdata with segmentation datasets and leverages the `DHS.rates` package to calculate neonatal (NNMR), post-neonatal (PNNMR), infant (IMR), child (CMR), and U5MR estimates. As new geographies or survey types are documented, add their materials as peer subdirectories and reference them here.

Current examples:
- `U5MR for DHS Solutions` – Jess Long’s Kenya (2022 DHS 8) and Northern Nigeria (2018 DHS 7) scripts that adapt DHS indicator code and Pathways segment merges to estimate U5MR by segment, region, and urban/rural strata.

When contributing new analyses:
1. Include a README in the new subfolder summarizing inputs, dependencies, and outputs.
2. Cite any DHS or Pathways datasets using placeholder `#` links if they cannot be embedded.
3. Update this parent README to briefly describe the new example so collaborators can find it quickly.

