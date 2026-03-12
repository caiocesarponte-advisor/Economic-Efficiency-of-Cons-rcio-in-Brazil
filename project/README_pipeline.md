# R Pipeline: Economic Efficiency of Consortium in Brazil

This repository contains a **fully reproducible data pipeline in R** used to analyze the **economic efficiency of the consortium system in Brazil**, compared with:

1. Bank financing  
2. Autonomous capital accumulation (savings)

The pipeline downloads public data, processes it, constructs analytical datasets, runs comparative simulations, and generates figures used in the research.

The analysis relies primarily on **institutional data sources**, especially the **Central Bank of Brazil (BCB)** and the **IBGE SIDRA system**.

---

# Pipeline Structure

The project follows a modular pipeline architecture:

project/  
│  
├─ run_pipeline.R  
│  
├─ scripts/  
│   ├─ utils.R  
│   ├─ ingestion.R  
│   ├─ processing.R  
│   ├─ transformation.R  
│   └─ visualization.R  
│  
├─ data/  
│   ├─ raw/  
│   ├─ interim/  
│   ├─ processed/  
│   └─ manual/  
│  
└─ figures/  

### Module description

| Script | Purpose |
|------|------|
| utils.R | Utility helpers (logging, safe execution, numeric cleaning, plotting utilities) |
| ingestion.R | Download and persistence of raw datasets |
| processing.R | Data cleaning, harmonization, and provenance metadata |
| transformation.R | Analytical tables and simulation scenarios |
| visualization.R | Generation of article-ready figures |
| run_pipeline.R | Main orchestration script |

---

# Execution Instructions

## 1. Install R dependencies

Run in R:

install.packages(c(
  "tidyverse",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "lubridate",
  "janitor",
  "purrr",
  "ggplot2",
  "scales",
  "jsonlite",
  "httr2",
  "sidrar",
  "rbcb",
  "fs",
  "here"
))

---

## 2. Run the pipeline

From the repository root:

Rscript project/run_pipeline.R

The script executes the following steps:

1. Directory initialization  
2. Data ingestion (BCB Open Data, SGS, SIDRA)  
3. Data cleaning and harmonization  
4. Construction of analytical datasets  
5. Economic simulation of acquisition scenarios  
6. Generation of figures  

---

# Outputs

After execution, the pipeline generates:

## Processed datasets

Location:

project/data/processed/

Files generated:

annual_consorcio_summary.csv  
monthly_credit_parameters.csv  
macro_parameters.csv  
manual_panorama_series.csv  
simulation_results.csv  
simulation_cashflows.csv  

---

## Figures

Location:

project/figures/

Figures include:

1. Active consortium quotas in Brazil  
2. Consortium exclusion rate  
3. Administrative fees by consortium segment  
4. Average consortium term by segment  
5. Financing rates (vehicle vs housing)  
6. Total cost comparison (vehicle)  
7. Total cost comparison (housing)  
8. Time to acquisition comparison (vehicle)  
9. Time to acquisition comparison (housing)  
10. Opportunity cost comparison (vehicle)  
11. Opportunity cost comparison (housing)  
12. Sensitivity analysis  

Figures are exported as:

PNG (high resolution)  
PDF (vector format for academic publication)

---

# Data Sources

The pipeline relies on publicly available institutional data.

### Central Bank of Brazil (BCB)

BCB Open Data Portal:

https://dadosabertos.bcb.gov.br

Used datasets include:

- Active consortium quotas  
- Excluded quotas  
- Consortium exclusion index  

---

### BCB SGS (Time Series System)

Accessed via the **rbcb R package**.

Series used:

| SGS Code | Description |
|------|------|
| 25471 | Vehicle financing interest rate |
| 20886 | Average vehicle financing term |
| 25497 | Housing financing interest rate |
| 20912 | Average housing financing term |
| 432 | Selic interest rate |

---

### IBGE SIDRA

Inflation data (IPCA)

SIDRA table:

1737

Accessed through the **sidrar R package**.

---

# Manual Data Requirement

The **BCB Panorama Consortium reports** are published as PDF documents.

Because these reports **do not provide a stable tabular API**, the pipeline includes a manual extraction step.

The pipeline automatically generates a template file:

project/data/manual/manual_panorama_series_template.csv

You must manually fill this file using data extracted from Panorama reports (for example: 2022, 2023, 2024).

Required fields:

| Field | Description |
|------|------|
| year | Reference year |
| admin_fee_total | Average administrative fee (total market) |
| avg_term_total | Average consortium term (total) |
| admin_fee_auto | Administrative fee – vehicle consortium |
| avg_term_auto | Average term – vehicle consortium |
| admin_fee_housing | Administrative fee – housing consortium |
| avg_term_housing | Average term – housing consortium |

Also fill provenance metadata:

| Field | Description |
|------|------|
| source_dataset | Example: "BCB Panorama Consortium 2023" |
| source_url | Link to the Panorama report |
| note | Any clarification or observation |

---

# Reproducibility

The pipeline was designed to support **fully reproducible empirical research**.

Key principles:

- deterministic pipeline execution  
- raw data persistence  
- explicit provenance metadata  
- automated figure generation  
- modular processing steps  

All intermediate datasets are stored in the repository structure.

---

# Important Notes

1. If BCB changes the structure of Open Data datasets, update the ingestion functions.

2. If SGS codes change, update:

config$sgs_codes

in:

project/run_pipeline.R

3. Manual Panorama data must be updated whenever new reports are published.

---

# License

This repository is intended for **academic research and reproducible economic analysis**.