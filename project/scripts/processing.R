# Processing functions: cleaning, harmonization, provenance columns.

process_consorcio_raw <- function(file_paths, config) {
  active <- read_csv_safe(file_paths$active_quotas) %>%
    clean_names() %>%
    mutate(across(where(is.character), str_trim))

  excluded <- read_csv_safe(file_paths$excluded_quotas) %>%
    clean_names() %>%
    mutate(across(where(is.character), str_trim))

  exclusion_index <- read_csv_safe(file_paths$exclusion_index) %>%
    clean_names() %>%
    mutate(across(where(is.character), str_trim))

  list(active = active, excluded = excluded, exclusion_index = exclusion_index)
}

process_credit_and_selic_raw <- function(file_paths, config) {
  read_csv_safe(file_paths$credit_sgs) %>%
    clean_names() %>%
    mutate(
      date = as_date(date),
      across(c(vehicle_interest_rate, vehicle_term_months, housing_interest_rate, housing_term_months, selic_rate), as.numeric),
      source_dataset = "BCB SGS",
      source_url = "https://www.bcb.gov.br"
    )
}

process_ipca_raw <- function(file_paths, config) {
  read_csv_safe(file_paths$ipca) %>%
    clean_names() %>%
    transmute(
      date = suppressWarnings(parse_date_time(mes_codigo, orders = c("Ym", "Y-m")) %>% as_date()),
      ipca_monthly = clean_numeric(valor),
      source_dataset = "SIDRA table 1737",
      source_url = config$inflation$ipca_sidra_url
    ) %>%
    filter(!is.na(date))
}

process_manual_panorama <- function(manual_file) {
  read_csv_safe(manual_file) %>%
    clean_names() %>%
    mutate(year = as.integer(year))
}
