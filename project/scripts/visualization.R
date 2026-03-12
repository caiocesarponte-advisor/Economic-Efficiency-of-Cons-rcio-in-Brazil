theme_article <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(size = 10),
      axis.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

generate_figures <- function(annual_consorcio_summary,
                             monthly_credit_parameters,
                             manual_panorama_series,
                             simulation_results,
                             base_dir = "project") {
  figure_dir <- fs::path(base_dir, "figures")
  fs::dir_create(figure_dir)

  scenario_levels <- c(
    "consortium_early",
    "consortium_mid",
    "consortium_late",
    "financing",
    "autonomous_savings"
  )

  outputs <- list()

  p1 <- annual_consorcio_summary %>%
    ggplot(aes(x = year, y = active_quotas_total)) +
    geom_line() +
    geom_point() +
    labs(
      title = "Active consortium quotas in Brazil",
      subtitle = "Source: BCB Open Data",
      x = "Year",
      y = "Total active quotas"
    ) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    theme_article()

  outputs$graph1 <- save_dual_plot(p1, path(figure_dir, "graph1_active_quotas"))

  p2 <- annual_consorcio_summary %>%
    ggplot(aes(x = year, y = exclusion_rate)) +
    geom_line() +
    geom_point() +
    scale_y_continuous(labels = percent_format()) +
    labs(
      title = "Consortium exclusion rate",
      subtitle = "Source: BCB Open Data",
      x = "Year",
      y = "Exclusion rate"
    ) +
    theme_article()

  outputs$graph2 <- save_dual_plot(p2, path(figure_dir, "graph2_exclusion_rate"))

  invisible(outputs)
}