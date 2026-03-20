annuity_payment <- function(principal, monthly_rate, n_months) {
  if (monthly_rate <= 0) return(principal / n_months)
  principal * (monthly_rate * (1 + monthly_rate)^n_months) / ((1 + monthly_rate)^n_months - 1)
}

future_value_annuity_payment <- function(target_value, monthly_rate, n_months) {
  if (monthly_rate <= 0) return(target_value / n_months)
  target_value * monthly_rate / ((1 + monthly_rate)^n_months - 1)
}

build_annual_consorcio_summary <- function(consorcio_processed, config) {
  validate_for_plot <- function(df, table_label, value_col) {
    log_info(sprintf("[%s] Rows after annual aggregation: %s", table_label, nrow(df)))
    log_info(sprintf("[%s] Columns available: %s", table_label, paste(names(df), collapse = ", ")))

    if (nrow(df) == 0) {
      stop(sprintf("[%s] Annual summary is empty after processing.", table_label))
    }

    na_year <- sum(is.na(df$Year))
    na_value <- sum(is.na(df[[value_col]]))
    log_info(sprintf("[%s] NA count - Year: %s | %s: %s", table_label, na_year, value_col, na_value))

    if (all(is.na(df[[value_col]]))) {
      stop(sprintf("[%s] Column '%s' has only NA values.", table_label, value_col))
    }

    df
  }

  active <- consorcio_processed$active %>%
    mutate(Year = as.integer(year(date))) %>%
    filter(!is.na(Year)) %>%
    group_by(Year) %>%
    summarise(ActiveQuotas = mean(active_quotas, na.rm = TRUE), .groups = "drop") %>%
    mutate(ActiveQuotas = if_else(is.nan(ActiveQuotas), NA_real_, ActiveQuotas)) %>%
    validate_for_plot("active_quotas", "ActiveQuotas")

  exclusion <- consorcio_processed$exclusion_index %>%
    mutate(Year = as.integer(year(date))) %>%
    filter(!is.na(Year)) %>%
    group_by(Year) %>%
    summarise(ExclusionRate = mean(exclusion_rate, na.rm = TRUE), .groups = "drop") %>%
    mutate(ExclusionRate = if_else(is.nan(ExclusionRate), NA_real_, ExclusionRate)) %>%
    validate_for_plot("exclusion_index", "ExclusionRate")

  active %>%
    left_join(exclusion, by = "Year") %>%
    arrange(Year)
}


build_monthly_credit_parameters <- function(credit_processed, config) {
  credit_processed %>%
    mutate(
      date = as_date(date)
    ) %>%
    arrange(date)
}

build_macro_parameters <- function(credit_processed, ipca_processed, config) {
  # Methodological choice: IPCA is monthly and central for real-value interpretation.
  # Selic can be absent because it is daily and subject to BCB 10-year API windows;
  # when unavailable, macro table remains valid for inflation-tracking analyses.
  macro <- credit_processed %>%
    select(
      date,
      vehicle_interest_rate,
      housing_interest_rate,
      any_of("selic_rate")
    ) %>%
    left_join(ipca_processed %>% select(date, ipca_monthly), by = "date") %>%
    arrange(date)

  if (!"selic_rate" %in% names(macro)) {
    macro <- macro %>% mutate(selic_rate = NA_real_)
  }

  macro
}

simulate_asset <- function(asset_name, asset_value, params, credit_row, manual_panorama) {
  monthly_discount <- (1 + params$discount_rate_annual)^(1 / 12) - 1
  admin_fee_pct <- params$admin_fee_default

  if (nrow(manual_panorama) > 0) {
    if (asset_name == "vehicle" && any(!is.na(manual_panorama$admin_fee_auto))) {
      admin_fee_pct <- dplyr::last(na.omit(manual_panorama$admin_fee_auto)) / 100
    }
    if (asset_name == "housing" && any(!is.na(manual_panorama$admin_fee_housing))) {
      admin_fee_pct <- dplyr::last(na.omit(manual_panorama$admin_fee_housing)) / 100
    }
  }

  if (asset_name == "vehicle") {
    financing_rate_monthly <- (credit_row$vehicle_interest_rate %||% params$fallback_vehicle_rate) / 100
    financing_term <- round(credit_row$vehicle_term_months %||% params$fallback_vehicle_term)
  } else {
    financing_rate_monthly <- (credit_row$housing_interest_rate %||% params$fallback_housing_rate) / 100
    financing_term <- round(credit_row$housing_term_months %||% params$fallback_housing_term)
  }

  financing_payment <- annuity_payment(asset_value, financing_rate_monthly, financing_term)

  consortium_term <- params$consortium_term_months
  consortium_payment <- (asset_value * (1 + admin_fee_pct)) / consortium_term

  autonomous_rate_monthly <- (1 + params$autonomous_return_annual)^(1 / 12) - 1
  autonomous_monthly_contribution <- future_value_annuity_payment(
    asset_value,
    autonomous_rate_monthly,
    params$autonomous_target_months
  )

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
    pmap_dfr(function(scenario, months_until_acquisition, monthly_cash_flow, n_payments, asset) {
      tibble(
        asset = asset,
        scenario = scenario,
        month = seq_len(n_payments),
        monthly_cash_flow = monthly_cash_flow
      )
    })

  list(summary = summary, cashflows = cashflows)
}

run_simulations <- function(monthly_credit_parameters, manual_panorama, params) {
  latest_credit <- monthly_credit_parameters %>%
    filter(!is.na(date)) %>%
    arrange(date) %>%
    tail(1)

  if (nrow(latest_credit) == 0) {
    latest_credit <- tibble(
      vehicle_interest_rate = params$fallback_vehicle_rate,
      vehicle_term_months = params$fallback_vehicle_term,
      housing_interest_rate = params$fallback_housing_rate,
      housing_term_months = params$fallback_housing_term
    )
  }

  vehicle <- simulate_asset("vehicle", params$vehicle_value, params, latest_credit, manual_panorama)
  housing <- simulate_asset("housing", params$housing_value, params, latest_credit, manual_panorama)

  list(
    simulation_results = bind_rows(vehicle$summary, housing$summary),
    simulation_cashflows = bind_rows(vehicle$cashflows, housing$cashflows)
  )
}
