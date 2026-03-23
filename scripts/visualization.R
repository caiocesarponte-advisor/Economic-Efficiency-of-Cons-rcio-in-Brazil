theme_article <- function() {
  theme_minimal(base_size = 11, base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 0),
      axis.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
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

# CORREÇÃO 1: "autonomous_savings" com 's' — alinhado com o dataset real
scenario_labels_pt <- c(
  "consortium_early"   = "Consórcio (contemplação antecipada)",
  "consortium_mid"     = "Consórcio (contemplação intermediária)",
  "consortium_late"    = "Consórcio (contemplação tardia)",
  "financing"          = "Financiamento bancário",
  "autonomous_savings" = "Acumulação autônoma"
)

asset_labels_pt <- c(
  "vehicle" = "Veículo",
  "housing" = "Imóvel"
)

# Format currency in BRL style
format_brl <- function(x) {
  paste0("R$ ", formatC(x, format = "f", big.mark = ".", decimal.mark = ",", digits = 0))
}

generate_figures <- function(annual_consorcio_summary,
                             monthly_credit_parameters,
                             manual_panorama_series,
                             simulation_results,
                             simulation_cashflows = NULL,
                             base_dir = ".") {
  figure_dir <- fs::path(base_dir, "figures")
  fs::dir_create(figure_dir)

  # CORREÇÃO 1: "autonomous_savings" com 's' — alinhado com o dataset real
  scenario_levels <- c(
    "consortium_early",
    "consortium_mid",
    "consortium_late",
    "financing",
    "autonomous_savings"
  )

  outputs <- list()

  # ── Gráfico 1: Cotas ativas ──────────────────────────────────────────────────
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
      title = "Cotas ativas de consórcio no Brasil",
      x = "Ano",
      y = "Total de cotas ativas",
      caption = "Fonte: BCB Open Data"
    ) +
    scale_x_continuous(breaks = seq(2009, 2024, by = 1)) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    theme_article()

  outputs$graph1 <- save_dual_plot(p1, path(figure_dir, "fig01_cotas_ativas"))
  log_info("[viz] Gráfico 1 salvo: fig01_cotas_ativas")

  # ── Gráfico 2: Taxa de exclusão ─────────────────────────────────────────────
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
    scale_x_continuous(breaks = seq(2015, 2024, by = 1)) +
    scale_y_continuous(labels = percent_format(), limits = c(0.40, 0.55)) +
    labs(
      title = "Taxa de exclusão do sistema de consórcios",
      x = "Ano",
      y = "Taxa de exclusão",
      caption = "Fonte: BCB Open Data"
    ) +
    theme_article()

  outputs$graph2 <- save_dual_plot(p2, path(figure_dir, "fig02_taxa_exclusao"))
  log_info("[viz] Gráfico 2 salvo: fig02_taxa_exclusao")

  # ── Gráfico 3: Tabela visual de parâmetros (ano mais recente) ───────────────
  suppressPackageStartupMessages({
    if (!requireNamespace("gridExtra", quietly = TRUE)) {
      log_info("[viz] Pacote gridExtra não disponível, pulando Gráfico 3")
    }
  })

  latest_year <- max(manual_panorama_series$year, na.rm = TRUE)
  params_row <- manual_panorama_series %>% filter(year == latest_year)

  # Detectar escala automaticamente: se > 1 já é percentual, se <= 1 converter
  fee_auto    <- params_row$admin_fee_auto
  fee_housing <- params_row$admin_fee_housing
  if (fee_auto <= 1)    fee_auto    <- fee_auto * 100
  if (fee_housing <= 1) fee_housing <- fee_housing * 100

  params_table <- tibble(
    `Parâmetro` = c(
      "Taxa de administração — Veículo",
      "Prazo médio — Veículo (meses)",
      "Taxa de administração — Imóvel",
      "Prazo médio — Imóvel (meses)"
    ),
    `Valor` = c(
      sprintf("%.2f%%", fee_auto),
      as.character(round(params_row$avg_term_auto)),
      sprintf("%.2f%%", fee_housing),
      as.character(round(params_row$avg_term_housing))
    )
  )

  table_grob <- gridExtra::tableGrob(
    params_table,
    rows = NULL,
    theme = gridExtra::ttheme_minimal(
      core = list(
        fg_params = list(fontsize = 10, fontfamily = "sans"),
        bg_params = list(fill = c("grey95", "white"))
      ),
      colhead = list(
        fg_params = list(fontsize = 11, fontface = "bold", fontfamily = "sans"),
        bg_params = list(fill = "grey80")
      )
    )
  )

  # CORREÇÃO 2: fundo branco explícito + xlim/ylim para renderização correta
  p3 <- ggplot() +
    xlim(0, 1) +
    ylim(0, 1) +
    annotation_custom(table_grob, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
    labs(
      title = sprintf("Parâmetros das simulações — Consórcio (%d)", latest_year),
      caption = "Fonte: BCB — Panorama do Sistema de Consórcios"
    ) +
    theme_void(base_family = "sans") +
    theme(
      plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
      plot.caption    = element_text(size = 8, color = "grey50", hjust = 0),
      plot.margin     = margin(10, 10, 10, 10),
      # CORREÇÃO 2: fundo branco explícito
      plot.background = element_rect(fill = "white", color = NA)
    )

  outputs$graph3 <- save_dual_plot(p3, path(figure_dir, "fig03_parametros"), width = 7, height = 3)
  log_info("[viz] Gráfico 3 salvo: fig03_parametros")

  # ── Preparação comum para Gráficos 4–6 ─────────────────────────────────────
  sim_data <- simulation_results %>%
    mutate(
      scenario    = factor(scenario, levels = scenario_levels),
      scenario_pt = factor(scenario_labels_pt[as.character(scenario)],
                           levels = scenario_labels_pt[scenario_levels]),
      asset_pt    = factor(asset_labels_pt[as.character(asset)],
                           levels = asset_labels_pt)
    )

  palette_scenarios <- c(
    "Consórcio (contemplação antecipada)"    = "#1b9e77",
    "Consórcio (contemplação intermediária)" = "#7570b3",
    "Consórcio (contemplação tardia)"        = "#d95f02",
    "Financiamento bancário"                 = "#e7298a",
    "Acumulação autônoma"                    = "#66a61e"
  )

  # ── Gráfico 4: Custo total desembolsado ────────────────────────────────────
  p4 <- sim_data %>%
    ggplot(aes(x = asset_pt, y = total_cost, fill = scenario_pt)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    scale_fill_manual(values = palette_scenarios, name = "Cenário") +
    scale_y_continuous(labels = function(x) format_brl(x)) +
    labs(
      title   = "Custo total desembolsado por mecanismo de aquisição",
      x       = "Tipo de bem",
      y       = "Custo total (R$)",
      caption = "Fonte: Simulação própria com dados do BCB"
    ) +
    theme_article() +
    guides(fill = guide_legend(nrow = 2))

  outputs$graph4 <- save_dual_plot(p4, path(figure_dir, "fig04_custo_total"), width = 9, height = 6)
  log_info("[viz] Gráfico 4 salvo: fig04_custo_total")

  # ── Gráfico 5: Valor presente dos custos ───────────────────────────────────
  p5 <- sim_data %>%
    ggplot(aes(x = asset_pt, y = present_value_cost, fill = scenario_pt)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    scale_fill_manual(values = palette_scenarios, name = "Cenário") +
    scale_y_continuous(labels = function(x) format_brl(x)) +
    labs(
      title   = "Valor presente dos desembolsos por mecanismo",
      x       = "Tipo de bem",
      y       = "Valor presente (R$)",
      caption = "Fonte: Simulação própria com dados do BCB"
    ) +
    theme_article() +
    guides(fill = guide_legend(nrow = 2))

  outputs$graph5 <- save_dual_plot(p5, path(figure_dir, "fig05_valor_presente"), width = 9, height = 6)
  log_info("[viz] Gráfico 5 salvo: fig05_valor_presente")

  # ── Gráfico 6: Custo de oportunidade ───────────────────────────────────────
  # CORREÇÃO 3: caption explica a escala do imóvel (valorização projetada ao longo de 215 meses)
  opp_data <- sim_data %>%
    mutate(
      opp_color = ifelse(opportunity_cost < 0, "Favorável", "Desfavorável")
    )

  p6 <- opp_data %>%
    ggplot(aes(x = scenario_pt, y = opportunity_cost, fill = opp_color)) +
    geom_col(width = 0.6) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    coord_flip() +
    facet_wrap(~ asset_pt, scales = "free_x", ncol = 1) +
    scale_fill_manual(
      values = c("Favorável" = "#1a6b3c", "Desfavorável" = "#8b1a1a"),
      name   = "Resultado"
    ) +
    scale_y_continuous(labels = function(x) format_brl(x)) +
    labs(
      title   = "Custo de oportunidade por cenário de aquisição",
      x       = NULL,
      y       = "Custo de oportunidade (R$)",
      caption = paste0(
        "Fonte: Simulação própria — opportunity_cost = fv_payments − fv_asset\n",
        "Nota: para o imóvel, a escala reflete a valorização projetada ao longo de até 215 meses de contrato."
      )
    ) +
    theme_article() +
    theme(strip.text = element_text(face = "bold", size = 11))

  outputs$graph6 <- save_dual_plot(p6, path(figure_dir, "fig06_custo_oportunidade"), width = 9, height = 7)
  log_info("[viz] Gráfico 6 salvo: fig06_custo_oportunidade")

  # ── Gráfico 7: Fluxo de caixa acumulado ────────────────────────────────────
  # CORREÇÃO 4: adicionar linhas verticais tracejadas no mês de contemplação
  # para diferenciar visualmente os três cenários de consórcio (que têm mesmo
  # monthly_cash_flow e portanto curvas acumuladas sobrepostas sem esse recurso)
  if (!is.null(simulation_cashflows) && nrow(simulation_cashflows) > 0) {

    cf_data <- simulation_cashflows %>%
      mutate(
        scenario    = factor(scenario, levels = scenario_levels),
        scenario_pt = factor(scenario_labels_pt[as.character(scenario)],
                             levels = scenario_labels_pt[scenario_levels]),
        asset_pt    = factor(asset_labels_pt[as.character(asset)],
                             levels = asset_labels_pt)
      ) %>%
      group_by(asset, scenario, scenario_pt, asset_pt) %>%
      arrange(month) %>%
      mutate(cumulative_cf = cumsum(monthly_cash_flow)) %>%
      ungroup()

    # Meses de contemplação por cenário e bem, para as linhas verticais
    contemplation_lines <- simulation_results %>%
      filter(scenario %in% c("consortium_early", "consortium_mid", "consortium_late")) %>%
      mutate(
        scenario_pt = factor(scenario_labels_pt[as.character(scenario)],
                             levels = scenario_labels_pt[scenario_levels]),
        asset_pt    = factor(asset_labels_pt[as.character(asset)],
                             levels = asset_labels_pt)
      ) %>%
      select(asset_pt, scenario_pt, months_until_acquisition)

    p7 <- cf_data %>%
      ggplot(aes(x = month, y = cumulative_cf, color = scenario_pt)) +
      geom_line(linewidth = 0.8) +
      # Linhas verticais tracejadas indicando o mês de contemplação de cada cenário
      geom_vline(
        data        = contemplation_lines,
        aes(xintercept = months_until_acquisition, color = scenario_pt),
        linetype    = "dashed",
        linewidth   = 0.5,
        alpha       = 0.7
      ) +
      facet_wrap(~ asset_pt, scales = "free", ncol = 1) +
      scale_color_manual(values = palette_scenarios, name = "Cenário") +
      scale_y_continuous(labels = function(x) format_brl(x)) +
      labs(
        title    = "Fluxo de caixa acumulado por cenário",
        subtitle = "Linhas tracejadas verticais indicam o mês de contemplação (cenários de consórcio)",
        x        = "Mês",
        y        = "Fluxo acumulado (R$)",
        caption  = "Fonte: Simulação própria com dados do BCB"
      ) +
      theme_article() +
      theme(strip.text = element_text(face = "bold", size = 11)) +
      guides(color = guide_legend(nrow = 2))

    outputs$graph7 <- save_dual_plot(p7, path(figure_dir, "fig07_fluxo_acumulado"), width = 9, height = 8)
    log_info("[viz] Gráfico 7 salvo: fig07_fluxo_acumulado")
  } else {
    log_info("[viz] simulation_cashflows não disponível, Gráfico 7 não gerado")
  }

  # ── Gráfico 8: Painel síntese com patchwork ───────────────────────────────
  suppressPackageStartupMessages({
    if (!requireNamespace("patchwork", quietly = TRUE)) {
      log_info("[viz] Pacote patchwork não disponível, pulando Gráfico 8")
    }
  })

  p8 <- (p4 / p5 / p6) +
    patchwork::plot_annotation(
      title = "Comparativo de eficiência econômica — veículo e imóvel",
      theme = theme(
        plot.title = element_text(face = "bold", size = 15, hjust = 0.5, family = "sans")
      )
    )

  ggsave(
    filename = path(figure_dir, "fig08_painel_sintese.png"),
    plot     = p8,
    width    = 10, height = 18, dpi = 300
  )
  tryCatch(
    ggsave(
      filename = path(figure_dir, "fig08_painel_sintese.pdf"),
      plot     = p8,
      width    = 10, height = 18, device = cairo_pdf
    ),
    error = function(e) {
      ggsave(
        filename = path(figure_dir, "fig08_painel_sintese.pdf"),
        plot     = p8,
        width    = 10, height = 18
      )
    }
  )
  outputs$graph8 <- list(
    png = path(figure_dir, "fig08_painel_sintese.png"),
    pdf = path(figure_dir, "fig08_painel_sintese.pdf")
  )
  log_info("[viz] Gráfico 8 salvo: fig08_painel_sintese")

  invisible(outputs)
}