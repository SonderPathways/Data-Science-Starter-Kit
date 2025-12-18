# Health Utilization Score Examples

This directory houses reproducible examples of Sonder’s maternal and child health utilization scoring workflow. Each sub-project documents how we combined segmentation outputs with survey microdata to build composite indicators and weighted summaries. Use these examples as templates when adapting the score to other datasets or geographies.

- **Lagos DHS health utilization score** – Nigeria 2013 DHS-based workflow that links Pathways segments to DHS recodes, defines zero-dose children, and computes weighted service uptake at the segment level. See `lagos_health_utilization/readme.md`.
- **Nigeria Pathways Survey (PWS) health utilization score** – Pathways survey implementation that rebuilds the score using PWS-specific proxies, handles rural/urban segment classes, and exports Excel summaries by segment and profile. See `NN_PWS_health_utilization/readme.md`.

All raw data files referenced in the subdirectories have been removed from the repository; update the placeholder download links in each project README with the secure storage locations you maintain for the DHS and PWS datasets.

