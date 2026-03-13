# ==========================================================
# Debug script — Inspect processed datasets
# ==========================================================

library(readr)

cat("\n==============================\n")
cat("RUN DEBUG - DATASET INSPECTION\n")
cat("==============================\n\n")

# ----------------------------------------------------------
# Load datasets
# ----------------------------------------------------------

annual_consorcio_summary <- read_csv("project/data/processed/annual_consorcio_summary.csv")

macro_parameters <- read_csv("project/data/processed/macro_parameters.csv")

manual_panorama_series <- read_csv("project/data/processed/manual_panorama_series.csv")

monthly_credit_parameters <- read_csv("project/data/processed/monthly_credit_parameters.csv")

simulation_cashflows <- read_csv("project/data/processed/simulation_cashflows.csv")

simulation_results <- read_csv("project/data/processed/simulation_results.csv")

# ----------------------------------------------------------
# Helper function
# ----------------------------------------------------------

inspect_dataset <- function(dataset, name) {

  cat("\n--------------------------------------------\n")
  cat("DATASET:", name, "\n")
  cat("--------------------------------------------\n\n")

  cat("Structure:\n")
  print(str(dataset))

  cat("\nFirst 5 rows:\n")
  print(head(dataset, 5))

  cat("\n")
}

# ----------------------------------------------------------
# Inspect datasets
# ----------------------------------------------------------

inspect_dataset(annual_consorcio_summary, "annual_consorcio_summary")

inspect_dataset(macro_parameters, "macro_parameters")

inspect_dataset(manual_panorama_series, "manual_panorama_series")

inspect_dataset(monthly_credit_parameters, "monthly_credit_parameters")

inspect_dataset(simulation_cashflows, "simulation_cashflows")

inspect_dataset(simulation_results, "simulation_results")

cat("\n==============================\n")
cat("DEBUG COMPLETE\n")
cat("==============================\n\n")