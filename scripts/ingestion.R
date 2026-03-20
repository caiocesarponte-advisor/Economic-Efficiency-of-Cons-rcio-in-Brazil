# Ingestion functions: data download and initial raw persistence.

extract_dataset_slug <- function(dataset_url) {
  slug_match <- str_match(dataset_url, "dataset/([^/?#]+)")
  if (is.na(slug_match[1, 2])) {
    stop(sprintf("Could not extract dataset slug from URL: %s", dataset_url))
  }
  slug_match[1, 2]
}

get_ckan_resource_url <- function(dataset_url) {
  dataset_slug <- extract_dataset_slug(dataset_url)
  api_url <- sprintf(
    "https://dadosabertos.bcb.gov.br/api/3/action/package_show?id=%s",
    dataset_slug
  )

  response <- request(api_url) %>% req_perform()
  payload <- response %>% resp_body_json(simplifyVector = TRUE)

  if (!isTRUE(payload$success)) {
    stop(sprintf(
      "BCB CKAN API returned unsuccessful response for dataset '%s'",
      dataset_slug
    ))
  }

  resources <- payload$result$resources %>%
    as_tibble() %>%
    mutate(
      format = as.character(format),
      url = as.character(url),
      name = as.character(name),
      format_lower = str_to_lower(coalesce(format, "")),
      url_lower = str_to_lower(coalesce(url, "")),
      name_lower = str_to_lower(coalesce(name, ""))
    ) %>%
    filter(format_lower %in% c("csv", "txt") | str_detect(url_lower, "\\.csv"))

  if (nrow(resources) == 0) {
    stop(sprintf(
      "No CSV/TXT resource found in dataset '%s'",
      dataset_slug
    ))
  }

  resources %>%
    mutate(priority = case_when(
      format_lower == "csv" ~ 1,
      str_detect(url_lower, "\\.csv") ~ 2,
      format_lower == "txt" ~ 3,
      TRUE ~ 99
    )) %>%
    arrange(priority) %>%
    pull(url) %>%
    .[[1]]
}

download_ckan_dataset <- function(dataset_url, output_file) {
  dir_create(path_dir(output_file))
  direct_url <- get_ckan_resource_url(dataset_url)
  log_info(sprintf("Downloading CKAN dataset from: %s", direct_url))

  request(direct_url) %>%
    req_perform(path = output_file)

  output_file
}

ingest_consorcio_datasets <- function(config, base_dir = "project") {
  raw_dir <- path(base_dir, "data", "raw")
  dir_create(raw_dir)

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
  raw_dir <- path(base_dir, "data", "raw")
  dir_create(raw_dir)

  fetch_sgs_series <- function(series_code, series_name, start_date, end_date) {
    sgs_url <- sprintf(
      "https://api.bcb.gov.br/dados/serie/bcdata.sgs.%s/dados",
      series_code
    )

    response <- request(sgs_url) %>%
      req_url_query(
        formato = "csv",
        dataInicial = format(start_date, "%d/%m/%Y"),
        dataFinal = format(end_date, "%d/%m/%Y")
      ) %>%
      req_perform()

    payload <- response %>% resp_body_string()

    parse_sgs_payload <- function(raw_payload, delimiter) {
      read_delim(
        file = I(raw_payload),
        delim = delimiter,
        col_types = cols(.default = col_character()),
        locale = locale(decimal_mark = ","),
        show_col_types = FALSE,
        trim_ws = TRUE
      )
    }

    series_raw <- suppressWarnings(parse_sgs_payload(payload, ";"))

    if (!all(c("data", "valor") %in% make_clean_names(names(series_raw)))) {
      series_raw <- suppressWarnings(parse_sgs_payload(payload, ","))
    }

    normalized_names <- make_clean_names(names(series_raw))
    names(series_raw) <- normalized_names

    date_col <- names(series_raw)[names(series_raw) %in% c("data", "date")][1]
    value_col <- names(series_raw)[names(series_raw) %in% c("valor", "value")][1]

    if (is.na(date_col) || is.na(value_col)) {
      warning(sprintf(
        "Unexpected SGS response format for code %s (%s). Returning empty series.",
        series_code,
        series_name
      ))

      return(tibble(
        date = as.Date(character()),
        !!series_name := numeric()
      ))
    }

    series_raw %>%
      transmute(
        date = dmy(.data[[date_col]]),
        !!series_name := parse_number(.data[[value_col]], locale = locale(decimal_mark = ","))
      ) %>%
      filter(!is.na(date))
  }

  fetch_sgs_bundle <- function(series_map, start_date, end_date) {
    imap(series_map, function(series_code, series_name) {
      fetch_sgs_series(
        series_code = series_code,
        series_name = series_name,
        start_date = start_date,
        end_date = end_date
      )
    }) %>%
      reduce(full_join, by = "date") %>%
      arrange(date)
  }

  # We prioritize monthly SGS series in the main ingestion because they are
  # fully compatible with long historical windows (e.g., 2012+).
  # Daily Selic (code 432) is handled as optional and separate to avoid the
  # BCB API 10-year limit breaking the full pipeline.
  monthly_series <- c(
    vehicle_interest_rate = config$sgs_codes$vehicle_interest_rate,
    vehicle_term_months = config$sgs_codes$vehicle_term_months,
    housing_interest_rate = config$sgs_codes$housing_interest_rate,
    housing_term_months = config$sgs_codes$housing_term_months
  )

  series <- fetch_sgs_bundle(
    series_map = monthly_series,
    start_date = config$date_start,
    end_date = Sys.Date()
  ) %>%
    mutate(
      source_dataset = "BCB SGS API",
      source_url = "https://api.bcb.gov.br"
    )

  credit_file <- path(raw_dir, "credit_sgs_monthly.csv")
  write_csv(series, credit_file)

  files <- list(credit_sgs = credit_file)

  include_selic <- isTRUE(config$ingestion$include_optional_selic)
  has_selic_code <- !is.null(config$sgs_codes$selic_rate)

  if (include_selic && has_selic_code) {
    # SGS daily series (Selic 432) accepts at most ~10 years per request.
    # We cap the start date here so Selic can be used for diagnostics without
    # jeopardizing the core monthly-credit pipeline.
    selic_start <- max(config$date_start, Sys.Date() - lubridate::years(10))

    selic <- fetch_sgs_bundle(
      series_map = c(selic_rate = config$sgs_codes$selic_rate),
      start_date = selic_start,
      end_date = Sys.Date()
    ) %>%
      mutate(
        source_dataset = "BCB SGS API",
        source_url = "https://api.bcb.gov.br"
      )

    selic_file <- path(raw_dir, "selic_sgs_daily_optional.csv")
    write_csv(selic, selic_file)
    files$selic_sgs_optional <- selic_file
  }

  files
}

ingest_ipca_sidra <- function(config, base_dir = "project") {
  raw_dir <- path(base_dir, "data", "raw")
  dir_create(raw_dir)

  ipca <- sidrar::get_sidra(
    api = sprintf("/t/1737/n1/all/v/2266/p/%s?formato=json", config$sidra_period)
  ) %>%
    as_tibble()

  output_file <- path(raw_dir, "ipca_sidra_1737.csv")
  write_csv(ipca, output_file)

  list(ipca = output_file)
}

create_manual_panorama_template <- function(base_dir = "project") {
  manual_dir <- path(base_dir, "data", "manual")
  dir_create(manual_dir)

  manual_file <- path(manual_dir, "manual_panorama_series_template.csv")

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
