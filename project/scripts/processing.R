# Processing functions: cleaning, harmonization, provenance columns.

process_consorcio_raw <- function(file_paths, config) {
  stringify_scalar <- function(value) {
    if (is.null(value) || length(value) == 0) return(NA_character_)
    if (is.language(value) || is.expression(value)) return(paste(deparse(value), collapse = " "))
    if (is.list(value)) return(paste(map_chr(value, stringify_scalar), collapse = " "))
    paste(as.character(value), collapse = " ")
  }

  as_character_vector <- function(x) {
    if (is.atomic(x) && !is.list(x) && !is.expression(x)) {
      return(as.character(x))
    }

    map_chr(seq_along(x), ~stringify_scalar(x[[.x]]))
  }

  clean_table <- function(path_file) {
    read_csv_safe(path_file) %>%
      clean_names() %>%
      mutate(
        across(
          everything(),
          ~{
            as_character_vector(.x) %>%
              str_squish() %>%
              na_if("")
          }
        )
      )
  }

  parse_standard_date <- function(df) {
    canonical_date_cols <- c(
      "date", "data", "periodo", "mes", "month", "ano", "year",
      "data_base", "data_referencia", "periodo_referencia", "mes_referencia"
    )

    date_col <- canonical_date_cols[canonical_date_cols %in% names(df)][1]

    if (is.na(date_col)) {
      date_col <- names(df) %>%
        keep(~str_detect(.x, regex("date|data|periodo|mes|month|ano|year", ignore_case = TRUE))) %>%
        discard(~str_detect(.x, regex("valor|value|quant|qtd|cotas|indice|taxa|rate", ignore_case = TRUE))) %>%
        first()
    }

    if (!is.na(date_col)) {
      raw_date <- as_character_vector(df[[date_col]])

      parsed_date <- suppressWarnings(
        parse_date_time(
          raw_date,
          orders = c("dmy", "dmY", "ymd", "Ymd", "my", "Ym", "ym", "Y-m", "Y/m", "Y"),
          quiet = TRUE
        ) %>%
          as_date()
      )

      year_only <- suppressWarnings(parse_integer(str_extract(raw_date, "\\d{4}")))
      parsed_date <- coalesce(parsed_date, make_date(year_only, 1, 1))
      return(parsed_date)
    }

    year_col <- names(df)[str_detect(names(df), regex("^ano$|^year$|ano_referencia|year_reference", ignore_case = TRUE))][1]
    month_col <- names(df)[str_detect(names(df), regex("^mes$|^month$|mes_referencia|month_reference", ignore_case = TRUE))][1]

    if (!is.na(year_col) && !is.na(month_col)) {
      year_vec <- suppressWarnings(parse_integer(as_character_vector(df[[year_col]])))
      month_vec <- suppressWarnings(parse_integer(as_character_vector(df[[month_col]])))
      return(make_date(year_vec, month_vec, 1))
    }

    rep(as_date(NA), nrow(df))
  }

  extract_value_column <- function(df, candidates, table_label) {
    matched_col <- candidates[candidates %in% names(df)][1]

    if (is.na(matched_col)) {
      matched_col <- names(df) %>%
        keep(~str_detect(.x, regex(str_c(candidates, collapse = "|"), ignore_case = TRUE))) %>%
        first()
    }

    if (is.na(matched_col)) {
      stop(sprintf("[%s] Could not identify value column from candidates: %s", table_label, paste(candidates, collapse = ", ")))
    }

    values <- clean_numeric(as_character_vector(df[[matched_col]]))
    log_info(sprintf("[%s] Using value column: %s", table_label, matched_col))
    values
  }

  validate_processed_schema <- function(df, required_columns, table_label) {
    missing_columns <- setdiff(required_columns, names(df))
    if (length(missing_columns) > 0) {
      stop(sprintf("[%s] Missing required processed columns: %s", table_label, paste(missing_columns, collapse = ", ")))
    }

    if (!inherits(df$date, "Date")) {
      stop(sprintf("[%s] Column 'date' must be Date class.", table_label))
    }

    non_numeric_cols <- required_columns[str_detect(required_columns, "active_quotas|excluded_quotas|exclusion_rate")]
    for (col in non_numeric_cols) {
      if (!is.numeric(df[[col]])) {
        stop(sprintf("[%s] Column '%s' must be numeric.", table_label, col))
      }
    }

    if (!is.character(df$source_dataset) || !is.character(df$source_url)) {
      stop(sprintf("[%s] Provenance columns must be character.", table_label))
    }

    df
  }

  process_active_quotas_table <- function(df_raw, config) {
    df_raw %>%
      transmute(
        date = parse_standard_date(df_raw),
        active_quotas = extract_value_column(
          df_raw,
          c("n_cotas_ativas", "quantidade_cotas_ativas", "quantidade", "total", "valor"),
          table_label = "active_quotas"
        ),
        source_dataset = "BCB consorcio active quotas",
        source_url = as.character(config$consorcio$active_quotas_url)
      ) %>%
      filter(!is.na(date)) %>%
      validate_processed_schema(
        required_columns = c("date", "active_quotas", "source_dataset", "source_url"),
        table_label = "active_quotas"
      )
  }

  process_excluded_quotas_table <- function(df_raw, config) {
    df_raw %>%
      transmute(
        date = parse_standard_date(df_raw),
        excluded_quotas = extract_value_column(
          df_raw,
          c("quantidade_cotas_excluidas", "n_cotas_excluidas", "quantidade", "total", "valor"),
          table_label = "excluded_quotas"
        ),
        source_dataset = "BCB consorcio excluded quotas",
        source_url = as.character(config$consorcio$excluded_quotas_url)
      ) %>%
      filter(!is.na(date)) %>%
      validate_processed_schema(
        required_columns = c("date", "excluded_quotas", "source_dataset", "source_url"),
        table_label = "excluded_quotas"
      )
  }

  process_exclusion_index_table <- function(df_raw, config) {
    rate_values <- extract_value_column(
      df_raw,
      c("indice_exclusao", "indice_de_exclusao", "indice", "taxa", "valor"),
      table_label = "exclusion_index"
    )

    if (any(rate_values > 1, na.rm = TRUE)) {
      rate_values <- rate_values / 100
    }

    df_raw %>%
      transmute(
        date = parse_standard_date(df_raw),
        exclusion_rate = rate_values,
        source_dataset = "BCB consorcio exclusion index",
        source_url = as.character(config$consorcio$exclusion_index_url)
      ) %>%
      filter(!is.na(date)) %>%
      validate_processed_schema(
        required_columns = c("date", "exclusion_rate", "source_dataset", "source_url"),
        table_label = "exclusion_index"
      )
  }

  active_raw <- clean_table(file_paths$active_quotas)
  excluded_raw <- clean_table(file_paths$excluded_quotas)
  exclusion_index_raw <- clean_table(file_paths$exclusion_index)

  list(
    active = process_active_quotas_table(active_raw, config),
    excluded = process_excluded_quotas_table(excluded_raw, config),
    exclusion_index = process_exclusion_index_table(exclusion_index_raw, config)
  )
}

process_credit_and_selic_raw <- function(file_paths, config) {
  data <- read_csv_safe(file_paths$credit_sgs) %>%
    clean_names()

  # Selic is optional in this project stage because daily SGS windows can
  # exceed BCB API limits. Monthly credit series remain mandatory.
  required_columns <- c(
    "date",
    "vehicle_interest_rate",
    "vehicle_term_months",
    "housing_interest_rate",
    "housing_term_months"
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
        any_of(c("vehicle_interest_rate", "vehicle_term_months", "housing_interest_rate", "housing_term_months", "selic_rate")),
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