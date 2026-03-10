# Visualization functions for article-ready figures.

generate_figures <- function(annual_consorcio_summary,
                             monthly_credit_parameters,
                             manual_panorama_series,
                             simulation_results,
                             base_dir = "project") {
  figure_dir <- fs::path(base_dir, "figures")

  p1 <- annual_consorcio_summary %>%
    ggplot(aes(x = year, y = active_quotas_total)) +
    geom_line() +
    geom_point() +
    labs(
      title = "Active consortium quotas in Brazil",
      subtitle = "Source: BCB Open Data",
      x = "Year", y = "Total active quotas"
    ) +
    theme_minimal()
  save_dual_plot(p1, path(figure_dir, "graph1_active_quotas"))

  p2 <- annual_consorcio_summary %>%
    ggplot(aes(x = year, y = exclusion_rate)) +
    geom_line() +
    geom_point() +
    scale_y_continuous(labels = percent_format()) +
    labs(title = "Consortium exclusion rate", subtitle = "Source: BCB Open Data", x = "Year", y = "Exclusion rate") +
    theme_minimal()
  save_dual_plot(p2, path(figure_dir, "graph2_exclusion_rate"))

  p3 <- manual_panorama_series %>%
    pivot_longer(cols = c(admin_fee_total, admin_fee_auto, admin_fee_housing), names_to = "series", values_to = "value") %>%
    ggplot(aes(x = year, y = value, linetype = series)) +
    geom_line() +
    geom_point() +
    labs(title = "Administrative fee by consortium segment", subtitle = "Source: BCB Panorama (manual extraction)", x = "Year", y = "Administrative fee (%)") +
    theme_minimal()
  save_dual_plot(p3, path(figure_dir, "graph3_admin_fee"))

  p4 <- manual_panorama_series %>%
    pivot_longer(cols = c(avg_term_total, avg_term_auto, avg_term_housing), names_to = "series", values_to = "value") %>%
    ggplot(aes(x = year, y = value, linetype = series)) +
    geom_line() +
    geom_point() +
    labs(title = "Average consortium term by segment", subtitle = "Source: BCB Panorama (manual extraction)", x = "Year", y = "Months") +
    theme_minimal()
  save_dual_plot(p4, path(figure_dir, "graph4_avg_term"))

  p5 <- monthly_credit_parameters %>%
    pivot_longer(cols = c(vehicle_interest_rate, housing_interest_rate), names_to = "series", values_to = "value") %>%
    ggplot(aes(x = date, y = value / 100, linetype = series)) +
    geom_line() +
    scale_y_continuous(labels = percent_format()) +
    labs(title = "Financing rates: vehicles vs housing", subtitle = "Source: BCB SGS", x = "Date", y = "Monthly interest rate") +
    theme_minimal()
  save_dual_plot(p5, path(figure_dir, "graph5_financing_rates"))

  vehicle <- simulation_results %>% filter(asset == "vehicle")
  housing <- simulation_results %>% filter(asset == "housing")

  p6 <- vehicle %>% ggplot(aes(x = scenario, y = total_cost)) + geom_col() +
    labs(title = "Vehicle: total cost by scenario", x = "Scenario", y = "Total cost (BRL)") + theme_minimal()
  save_dual_plot(p6, path(figure_dir, "graph6_total_cost_comparison_vehicle"))

  p7 <- housing %>% ggplot(aes(x = scenario, y = total_cost)) + geom_col() +
    labs(title = "Housing: total cost by scenario", x = "Scenario", y = "Total cost (BRL)") + theme_minimal()
  save_dual_plot(p7, path(figure_dir, "graph7_total_cost_comparison_housing"))

  p8 <- vehicle %>% ggplot(aes(x = scenario, y = months_until_acquisition)) + geom_col() +
    labs(title = "Vehicle: months until acquisition", x = "Scenario", y = "Months") + theme_minimal()
  save_dual_plot(p8, path(figure_dir, "graph8_time_to_acquisition_vehicle"))

  p9 <- housing %>% ggplot(aes(x = scenario, y = months_until_acquisition)) + geom_col() +
    labs(title = "Housing: months until acquisition", x = "Scenario", y = "Months") + theme_minimal()
  save_dual_plot(p9, path(figure_dir, "graph9_time_to_acquisition_housing"))

  p10 <- vehicle %>% ggplot(aes(x = scenario, y = opportunity_cost)) + geom_col() +
    labs(title = "Vehicle: opportunity cost", x = "Scenario", y = "Opportunity cost (PV - asset value)") + theme_minimal()
  save_dual_plot(p10, path(figure_dir, "graph10_opportunity_cost_vehicle"))

  p11 <- housing %>% ggplot(aes(x = scenario, y = opportunity_cost)) + geom_col() +
    labs(title = "Housing: opportunity cost", x = "Scenario", y = "Opportunity cost (PV - asset value)") + theme_minimal()
  save_dual_plot(p11, path(figure_dir, "graph11_opportunity_cost_housing"))

  sensitivity <- expand_grid(
    discount_rate_annual = seq(0.06, 0.18, by = 0.02),
    admin_fee = seq(0.12, 0.24, by = 0.02)
  ) %>%
    mutate(
      pv_cost = (300000 * (1 + admin_fee) / 180) * (1 - (1 + discount_rate_annual / 12)^(-180)) / (discount_rate_annual / 12)
    )

  p12 <- sensitivity %>%
    ggplot(aes(x = discount_rate_annual, y = pv_cost, linetype = as.factor(admin_fee))) +
    geom_line() +
    scale_x_continuous(labels = percent_format()) +
    labs(
      title = "Sensitivity analysis: discount rate and admin fee",
      subtitle = "Reference asset: housing value BRL 300,000",
      x = "Annual discount rate", y = "Present value cost", linetype = "Admin fee"
    ) +
    theme_minimal()
  save_dual_plot(p12, path(figure_dir, "graph12_sensitivity_analysis"))
}
