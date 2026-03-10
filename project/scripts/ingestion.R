# Ingestion functions: data download and initial raw persistence.

extract_dataset_id <- function(dataset_url) {
  id_match <- str_match(dataset_url, "dataset/([0-9]+)-")
  if (is.na(id_match[1, 2])) {
    stop(sprintf("Could not extract dataset id from URL: %s", dataset_url))
  }
  id_match[1, 2]
}

get_ckan_resource_url <- function(dataset_url) {
  dataset_id <- extract_dataset_id(dataset_url)
  api_url <- sprintf("https://dadosabertos.bcb.gov.br/api/3/action/package_show?id=%s", dataset_id)

  response <- request(api_url) %>% req_perform()
  payload <- response %>% resp_body_json(simplifyVector = TRUE)

  if (!isTRUE(payload$success)) {
    stop(sprintf("BCB CKAN API returned unsuccessful response for id %s", dataset_id))
  }

  resources <- payload$result$resources
  csv_resources <- resources %>%
    as_tibble() %>%
    filter(str_to_lower(format) %in% c("csv", "txt") | str_detect(str_to_lower(url), "\\.csv"))

  if (nrow(csv_resources) == 0) {
    stop(sprintf("No CSV/TXT resource found in dataset id %s", dataset_id))
  }

  csv_resources$url[[1]]
}

download_ckan_dataset <- function(dataset_url, output_file) {
  direct_url <- get_ckan_resource_url(dataset_url)
  log_info(sprintf("Downloading CKAN dataset from: %s", direct_url))

  request(direct_url) %>%
    req_perform(path = output_file)

  output_file
}

ingest_consorcio_datasets <- function(config, base_dir = "project") {
  raw_dir <- path(base_dir, "data", "raw")

  files <- list(
    active_quotas = path(raw_dir, "consorcio_active_quotas.csv"),
    excluded_quotas = path(raw_dir, "consorcio_excluded_quotas.csv"),
    exclusion_index = path(raw_dir, "consorcio_exclusion_index.csv")
  )

  download_ckan_dataset(config$consorcio$active_quotas_url, files$active_quotas)
  download_ckan_dataset(config$consorcio$excluded_quotas_url, files$excluded_quotas)
  download_ckan_dataset(config$consorcio$exclusion_index_url, files$exclusion_index)

  files
}

ingest_credit_datasets <- function(config, base_dir = "project") {
  # Prefer SGS via rbcb::get_series where dataset IDs correspond to SGS series codes.
  series <- rbcb::get_series(
    c(
      vehicle_interest_rate = config$sgs_codes$vehicle_interest_rate,
      vehicle_term_months = config$sgs_codes$vehicle_term_months,
      housing_interest_rate = config$sgs_codes$housing_interest_rate,
      housing_term_months = config$sgs_codes$housing_term_months,
      selic_rate = config$sgs_codes$selic_rate
    ),
    start_date = config$date_start,
    end_date = Sys.Date()
  ) %>%
    as_tibble() %>%
    mutate(source_dataset = "BCB SGS via rbcb", source_url = "https://www.bcb.gov.br")

  credit_file <- path(base_dir, "data", "raw", "credit_and_selic_sgs.csv")
  write_csv(series, credit_file)

  list(credit_sgs = credit_file)
}

ingest_ipca_sidra <- function(config, base_dir = "project") {
  ipca <- sidrar::get_sidra(
    api = sprintf("/t/1737/n1/all/v/2266/p/%s?formato=json", config$sidra_period)
  ) %>%
    as_tibble()

  output_file <- path(base_dir, "data", "raw", "ipca_sidra_1737.csv")
  write_csv(ipca, output_file)

  list(ipca = output_file)
}

create_manual_panorama_template <- function(base_dir = "project") {
  manual_file <- path(base_dir, "data", "manual", "manual_panorama_series_template.csv")

  if (!file_exists(manual_file)) {
    template <- tibble(
      year = integer(),
      admin_fee_total = double(),
      avg_term_total = double(),
      admin_fee_auto = double(),
      avg_term_auto = double(),
      admin_fee_housing = double(),
      avg_term_housing = double(),
      source_dataset = character(),
      source_url = character(),
      note = character()
    )

    write_csv(template, manual_file)
  }

  manual_file
}
