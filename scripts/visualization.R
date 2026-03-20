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

validate_plot_input <- function(df, required_columns, table_label, y_col) {
  log_info(sprintf("[plot:%s] nrow = %s", table_label, nrow(df)))
  log_info(sprintf("[plot:%s] columns = %s", table_label, paste(names(df), collapse = ", ")))

  missing_columns <- setdiff(required_columns, names(df))
  if (length(missing_columns) > 0) {
    stop(sprintf(
      "[plot:%s] Missing required columns: %s",
      table_label,
      paste(missing_columns, collapse = ", ")
    ))
  }

  na_counts <- sapply(required_columns, function(col) sum(is.na(df[[col]])))
  log_info(sprintf(
    "[plot:%s] NA counts -> %s",
    table_label,
    paste(sprintf("%s=%s", names(na_counts), unname(na_counts)), collapse = " | ")
  ))

  if (nrow(df) == 0) {
    stop(sprintf("[plot:%s] Input dataframe is empty.", table_label))
  }

  if (all(is.na(df[[y_col]]))) {
    stop(sprintf("[plot:%s] Column '%s' has only NA values.", table_label, y_col))
  }

  df %>%
    filter(!is.na(.data[[required_columns[1]]]), !is.na(.data[[y_col]]))
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

  plot_active <- annual_consorcio_summary %>%
    validate_plot_input(
      required_columns = c("Year", "ActiveQuotas"),
      table_label = "active_quotas",
      y_col = "ActiveQuotas"
    )

  p1 <- plot_active %>%
    ggplot(aes(x = Year, y = ActiveQuotas)) +
    geom_line(linewidth = 1, color = "#1f78b4") +
    geom_point(size = 2, color = "#1f78b4") +
    labs(
      title = "Active consortium quotas in Brazil",
      subtitle = "Source: BCB Open Data",
      x = "Year",
      y = "Total active quotas"
    ) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    theme_article()

  outputs$graph1 <- save_dual_plot(p1, path(figure_dir, "graph1_active_quotas"))

  plot_exclusion <- annual_consorcio_summary %>%
    validate_plot_input(
      required_columns = c("Year", "ExclusionRate"),
      table_label = "exclusion_rate",
      y_col = "ExclusionRate"
    )

  p2 <- plot_exclusion %>%
    ggplot(aes(x = Year, y = ExclusionRate)) +
    geom_line(linewidth = 1, color = "#e31a1c") +
    geom_point(size = 2, color = "#e31a1c") +
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
