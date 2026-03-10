# R Pipeline: Economic Efficiency of Consortium in Brazil

## Execution instructions

1. Install dependencies in R:
   ```r
   install.packages(c(
     "tidyverse", "readr", "dplyr", "tidyr", "stringr", "lubridate", "janitor",
     "purrr", "ggplot2", "scales", "jsonlite", "httr2", "sidrar", "rbcb", "fs"
   ))
   ```
2. From the repository root, run:
   ```bash
   Rscript project/run_pipeline.R
   ```
3. Outputs will be generated in:
   - `project/data/processed/`
   - `project/figures/`
   - `project/data/manual/manual_panorama_series_template.csv`

## Data limitations and manual steps

- The BCB Panorama Consortium PDFs (2022, 2023, 2024) are not machine-readable with a stable open tabular endpoint in this repository.
- Therefore, this pipeline creates `project/data/manual/manual_panorama_series_template.csv` as a **manual placeholder**.
- You must manually extract and fill the fields from the Panorama PDFs:
  - `admin_fee_total`, `avg_term_total`
  - `admin_fee_auto`, `avg_term_auto`
  - `admin_fee_housing`, `avg_term_housing`
- Add provenance metadata in `source_dataset`, `source_url`, and `note` for each filled row.
- The pipeline uses `rbcb::get_series()` with SGS codes:
  - `25471` (vehicle interest rate)
  - `20886` (vehicle term)
  - `25497` (housing interest rate)
  - `20912` (housing term)
  - `432` (Selic)
- If any SGS code changes, update `config$sgs_codes` in `project/run_pipeline.R`.
