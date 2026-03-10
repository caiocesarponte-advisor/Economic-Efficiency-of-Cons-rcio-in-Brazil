# Transformation functions: analytical tables and scenario outputs.

infer_year_value_table <- function(df, value_regex) {
  date_col <- names(df)[str_detect(names(df), "(ano|year|data|period)")][1]
  value_col <- names(df)[str_detect(names(df), value_regex)][1]

  if (is.na(date_col) || is.na(value_col)) {
    stop("Failed to infer date/value columns from a consorcio source table.")
  }

  df %>%
    mutate(
      raw_date = as.character(.data[[date_col]]),
      year = suppressWarnings(as.integer(str_sub(raw_date, 1, 4))),
      year = if_else(year < 1900 | year > 2200, NA_integer_, year),
      year = coalesce(year, year(parse_date_time(raw_date, orders = c("Y", "Ym", "Ymd", "dmy", "mdy")))),
      value = clean_numeric(.data[[value_col]])
    ) %>%
    filter(!is.na(year)) %>%
    group_by(year) %>%
    summarise(value = mean(value, na.rm = TRUE), .groups = "drop")
}

build_annual_consorcio_summary <- function(consorcio_processed, config) {
  active_year <- infer_year_value_table(consorcio_processed$active, "(total|cota|quantidade|valor)") %>%
    rename(active_quotas_total = value)

  excluded_year <- infer_year_value_table(consorcio_processed$excluded, "(total|cota|quantidade|valor)") %>%
    rename(excluded_quotas_total = value)

  index_year <- infer_year_value_table(consorcio_processed$exclusion_index, "(indice|taxa|percent|valor)") %>%
    mutate(exclusion_rate = value / 100) %>%
    select(year, exclusion_rate)

  active_year %>%
    full_join(excluded_year, by = "year") %>%
    full_join(index_year, by = "year") %>%
    mutate(
      exclusion_rate = if_else(is.na(exclusion_rate) & !is.na(active_quotas_total) & active_quotas_total > 0,
        excluded_quotas_total / active_quotas_total,
        exclusion_rate
      ),
      source_dataset = "BCB consorcio open datasets",
      source_url = config$consorcio$panorama_url
    ) %>%
    arrange(year)
}

build_monthly_credit_parameters <- function(credit_processed, config) {
  credit_processed %>%
    transmute(
      date,
      vehicle_interest_rate,
      vehicle_term_months,
      housing_interest_rate,
      housing_term_months,
      source_dataset,
      source_url
    ) %>%
    arrange(date)
}

build_macro_parameters <- function(credit_processed, ipca_processed, config) {
  ipca_chain <- ipca_processed %>%
    arrange(date) %>%
    mutate(
      ipca_monthly = ipca_monthly / 100,
      ipca_index = cumprod(1 + replace_na(ipca_monthly, 0)),
      deflator = 1 / ipca_index
    )

  credit_processed %>%
    select(date, selic_rate) %>%
    distinct() %>%
    full_join(ipca_chain %>% select(date, ipca_index, ipca_monthly, deflator), by = "date") %>%
    arrange(date)
}

annuity_payment <- function(principal, monthly_rate, n_months) {
  if (monthly_rate <= 0) return(principal / n_months)
  principal * (monthly_rate * (1 + monthly_rate)^n_months) / ((1 + monthly_rate)^n_months - 1)
}

simulate_asset <- function(asset_name, asset_value, params, credit_row, macro_row, manual_panorama) {
  monthly_discount <- (1 + params$discount_rate_annual)^(1 / 12) - 1
  admin_fee_pct <- params$admin_fee_default

  if (nrow(manual_panorama) > 0) {
    if (asset_name == "vehicle" && any(!is.na(manual_panorama$admin_fee_auto))) admin_fee_pct <- dplyr::last(na.omit(manual_panorama$admin_fee_auto)) / 100
    if (asset_name == "housing" && any(!is.na(manual_panorama$admin_fee_housing))) admin_fee_pct <- dplyr::last(na.omit(manual_panorama$admin_fee_housing)) / 100
  }

  if (asset_name == "vehicle") {
    financing_rate <- (credit_row$vehicle_interest_rate %||% params$fallback_vehicle_rate) / 100
    financing_term <- round(credit_row$vehicle_term_months %||% params$fallback_vehicle_term)
  } else {
    financing_rate <- (credit_row$housing_interest_rate %||% params$fallback_housing_rate) / 100
    financing_term <- round(credit_row$housing_term_months %||% params$fallback_housing_term)
  }

  financing_rate_monthly <- financing_rate / 12
  financing_payment <- annuity_payment(asset_value, financing_rate_monthly, financing_term)

  consortium_term <- params$consortium_term_months
  consortium_payment <- (asset_value * (1 + admin_fee_pct)) / consortium_term

  autonomous_monthly_contribution <- asset_value / params$autonomous_target_months

  scenarios <- tribble(
    ~scenario, ~months_until_acquisition, ~monthly_cash_flow, ~n_payments,
    "consortium_early", params$consortium_early_month, consortium_payment, consortium_term,
    "consortium_mid", params$consortium_mid_month, consortium_payment, consortium_term,
    "consortium_late", params$consortium_late_month, consortium_payment, consortium_term,
    "financing", 1, financing_payment, financing_term,
    "autonomous_savings", params$autonomous_target_months, autonomous_monthly_contribution, params$autonomous_target_months
  )

  summary <- scenarios %>%
    mutate(
      total_cost = monthly_cash_flow * n_payments,
      present_value_cost = map2_dbl(monthly_cash_flow, n_payments, ~sum(.x / ((1 + monthly_discount)^(1:.y)))),
      opportunity_cost = present_value_cost - asset_value,
      asset = asset_name
    ) %>%
    select(asset, scenario, total_cost, present_value_cost, months_until_acquisition, opportunity_cost, monthly_cash_flow)

  cashflows <- scenarios %>%
    mutate(asset = asset_name) %>%
    rowwise() %>%
    do({
      tibble(
        asset = .$asset,
        scenario = .$scenario,
        month = seq_len(.$n_payments),
        monthly_cash_flow = .$monthly_cash_flow
      )
    }) %>%
    ungroup()

  list(summary = summary, cashflows = cashflows)
}

run_simulations <- function(monthly_credit_parameters, macro_parameters, manual_panorama, params) {
  credit_row <- monthly_credit_parameters %>% filter(date == max(date, na.rm = TRUE)) %>% slice(1)
  macro_row <- macro_parameters %>% filter(date == max(date, na.rm = TRUE)) %>% slice(1)

  vehicle <- simulate_asset("vehicle", params$vehicle_value, params, credit_row, macro_row, manual_panorama)
  housing <- simulate_asset("housing", params$housing_value, params, credit_row, macro_row, manual_panorama)

  list(
    simulation_results = bind_rows(vehicle$summary, housing$summary),
    simulation_cashflows = bind_rows(vehicle$cashflows, housing$cashflows)
  )
}
