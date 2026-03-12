# Processing functions: cleaning, harmonization, provenance columns.

process_consorcio_raw <- function(file_paths, config) {
  clean_table <- function(path_file) {
    read_csv_safe(path_file) %>%
      clean_names() %>%
      mutate(
        across(where(is.character), ~na_if(str_trim(.x), ""))
      )
  }

  list(
    active = clean_table(file_paths$active_quotas),
    excluded = clean_table(file_paths$excluded_quotas),
    exclusion_index = clean_table(file_paths$exclusion_index)
  )
}

process_credit_and_selic_raw <- function(file_paths, config) {
  data <- read_csv_safe(file_paths$credit_sgs) %>%
    clean_names()

  required_columns <- c(
    "date",
    "vehicle_interest_rate",
    "vehicle_term_months",
    "housing_interest_rate",
    "housing_term_months",
    "selic_rate"
  )

  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0) {
    stop(sprintf(
      "Missing required columns in credit SGS data: %s",
      paste(missing_columns, collapse = ", ")
    ))
  }

  data %>%
    mutate(
      date = as_date(date),
      across(
        c(vehicle_interest_rate, vehicle_term_months, housing_interest_rate, housing_term_months, selic_rate),
        as.numeric
      ),
      source_dataset = "BCB SGS",
      source_url = "https://www.bcb.gov.br"
    )
}

process_ipca_raw <- function(file_paths, config) {
  data <- read_csv_safe(file_paths$ipca) %>%
    clean_names()

  date_column <- names(data)[str_detect(names(data), "mes.*codigo|periodo|mes_codigo")][1]
  value_column <- names(data)[str_detect(names(data), "^valor$|valor")][1]

  if (is.na(date_column) || is.na(value_column)) {
    stop("Could not identify date/value columns in SIDRA IPCA raw data.")
  }

  data %>%
    transmute(
      date = suppressWarnings(parse_date_time(.data[[date_column]], orders = c("Ym", "Y-m")) %>% as_date()),
      ipca_monthly = clean_numeric(.data[[value_column]]),
      source_dataset = "SIDRA table 1737",
      source_url = config$inflation$ipca_sidra_url
    ) %>%
    filter(!is.na(date))
}

process_manual_panorama <- function(manual_file) {
  read_csv_safe(manual_file) %>%
    clean_names() %>%
    mutate(
      year = as.integer(year),
      across(
        c(
          admin_fee_total,
          avg_term_total,
          admin_fee_auto,
          avg_term_auto,
          admin_fee_housing,
          avg_term_housing
        ),
        as.numeric
      )
    )
}