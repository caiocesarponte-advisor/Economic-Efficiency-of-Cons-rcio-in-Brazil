#!/usr/bin/env Rscript

# Main reproducible pipeline for comparing economic efficiency of:
# (1) consortium, (2) bank financing, and (3) autonomous savings.

source(here::here("scripts", "utils.R"))
source(here::here("scripts", "ingestion.R"))
source(here::here("scripts", "processing.R"))
source(here::here("scripts", "transformation.R"))
source(here::here("scripts", "visualization.R"))

config <- list(
  date_start = as.Date("2012-01-01"),
  sidra_period = "all",
  consorcio = list(
    panorama_url = "https://www.bcb.gov.br/estabilidadefinanceira/panoramaconsorcio",
    active_quotas_url = "https://dadosabertos.bcb.gov.br/dataset/27459-cotas-ativas-por-tipo-de-administradora---total",
    excluded_quotas_url = "https://dadosabertos.bcb.gov.br/dataset/27487-quantidade-de-cotas-excluidas-por-tipo-de-bem---consolidado",
    exclusion_index_url = "https://dadosabertos.bcb.gov.br/dataset/27488-indice-de-exclusao-por-tipo-de-bem---consolidado"
  ),
  inflation = list(
    ipca_sidra_url = "https://sidra.ibge.gov.br/tabela/1737"
  ),
  sgs_codes = list(
    vehicle_interest_rate = 25471,
    vehicle_term_months = 20886,
    housing_interest_rate = 25497,
    housing_term_months = 20912
  ),
  ingestion = list(
    include_optional_selic = TRUE
  ),
  simulation = list(
    vehicle_value = 80000,
    housing_value = 300000,
    admin_fee_default = 0.1795,

    # Asset-specific consortium parameters
    vehicle_consortium_term = 90,
    vehicle_early_month = 1,
    vehicle_mid_month = 45,
    vehicle_late_month = 90,

    housing_consortium_term = 215,
    housing_early_month = 1,
    housing_mid_month = 107,
    housing_late_month = 215,

    autonomous_target_months = 84,

    fallback_vehicle_rate = 2.2,
    fallback_vehicle_term = 48,
    fallback_housing_rate = 0.9,
    fallback_housing_term = 240
  )
)

safe_run("Setup directories", function() ensure_directories("."))

consorcio_files <- safe_run("Ingestion - consorcio datasets", function() ingest_consorcio_datasets(config))
credit_files <- safe_run("Ingestion - credit (SGS monthly)", function() ingest_credit_datasets(config))
ipca_files <- safe_run("Ingestion - SIDRA IPCA", function() ingest_ipca_sidra(config))
manual_file <- safe_run("Ingestion - manual panorama template", function() create_manual_panorama_template())

consorcio_processed <- safe_run("Processing - consorcio", function() process_consorcio_raw(consorcio_files, config))
credit_processed <- safe_run("Processing - credit (selic optional)", function() process_credit_and_selic_raw(credit_files, config))
ipca_processed <- safe_run("Processing - IPCA", function() process_ipca_raw(ipca_files, config))
manual_panorama <- safe_run("Processing - manual panorama", function() process_manual_panorama(manual_file))

annual_consorcio_summary <- safe_run("Transformation - annual consorcio summary", function() build_annual_consorcio_summary(consorcio_processed, config))
monthly_credit_parameters <- safe_run("Transformation - monthly credit parameters", function() build_monthly_credit_parameters(credit_processed, config))
macro_parameters <- safe_run("Transformation - macro parameters", function() build_macro_parameters(credit_processed, ipca_processed, config))

if (!is.null(macro_parameters) && "selic_rate" %in% names(macro_parameters) &&
    any(!is.na(macro_parameters$selic_rate))) {
  avg_selic_annual <- mean(macro_parameters$selic_rate, na.rm = TRUE) / 100
  config$simulation$discount_rate_annual <- avg_selic_annual
  config$simulation$autonomous_return_annual <- avg_selic_annual
  log_info(sprintf("Selic-derived discount rate: %.4f", avg_selic_annual))
} else {
  config$simulation$discount_rate_annual <- 0.1175
  config$simulation$autonomous_return_annual <- 0.1175
  log_info("Selic data unavailable; using fallback discount rate 11.75%")
}

simulation_outputs <- safe_run("Simulation", function() {
  run_simulations(
    monthly_credit_parameters = monthly_credit_parameters,
    manual_panorama = manual_panorama,
    params = config$simulation
  )
})

safe_run("Storage - processed tables", function() {
  fs::dir_create("data/processed")

  write_csv(annual_consorcio_summary, "data/processed/annual_consorcio_summary.csv")
  write_csv(monthly_credit_parameters, "data/processed/monthly_credit_parameters.csv")
  write_csv(macro_parameters, "data/processed/macro_parameters.csv")
  write_csv(manual_panorama, "data/processed/manual_panorama_series.csv")
  write_csv(simulation_outputs$simulation_results, "data/processed/simulation_results.csv")
  write_csv(simulation_outputs$simulation_cashflows, "data/processed/simulation_cashflows.csv")
  TRUE
})

safe_run("Visualization", function() {
  generate_figures(
    annual_consorcio_summary = annual_consorcio_summary,
    monthly_credit_parameters = monthly_credit_parameters,
    manual_panorama_series = manual_panorama,
    simulation_results = simulation_outputs$simulation_results,
    simulation_cashflows = simulation_outputs$simulation_cashflows,
    base_dir = "."
  )
  TRUE
})

log_info("Pipeline completed successfully.")
