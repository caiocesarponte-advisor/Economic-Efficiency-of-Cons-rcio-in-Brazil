future_value_annuity_payment <- function(target_value, monthly_rate, n_months) {
  if (monthly_rate <= 0) return(target_value / n_months)
  target_value * monthly_rate / ((1 + monthly_rate)^n_months - 1)
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