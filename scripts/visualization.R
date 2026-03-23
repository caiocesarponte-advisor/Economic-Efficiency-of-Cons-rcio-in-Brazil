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

# Shared labels for scenario translation
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

# Format opportunity cost with explicit sign
format_opp <- function(x) {
  ifelse(
    x < 0,
    paste0("− R$ ", formatC(abs(x), format = "f", big.mark = ".", decimal.mark = ",", digits = 0)),
    paste0("+ R$ ", formatC(x,      format = "f", big.mark = ".", decimal.mark = ",", digits = 0))
  )
}

generate_figures <- function(annual_consorcio_summary,
                             monthly_credit_parameters,
                             manual_panorama_series,
                             simulation_results,
                             simulation_cashflows = NULL,
                             base_dir = ".") {
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

  # ── Gráfico 1: Cotas ativas ──────────────────────────────────────────────────
  plot_active <- annual_consorcio_summary %>%
    validate_plot_input(
      required_columns = c("Year", "ActiveQuotas"),
      table_label = "active_quotas",
      y_col = "ActiveQuotas"
    )

  p1 <- plot_active %>%
    ggplot(aes(x = Year, y = ActiveQuotas)) +
    geom_line(linewidth = 1, color = "grey20") +
    geom_point(size = 2.5, color = "grey20") +
    labs(
      title   = "Cotas ativas de consórcio no Brasil",
      x       = "Ano",
      y       = "Total de cotas ativas",
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
    geom_line(linewidth = 1, color = "grey20") +
    geom_point(size = 2.5, color = "grey20") +
    scale_x_continuous(breaks = seq(2015, 2024, by = 1)) +
    scale_y_continuous(labels = percent_format(), limits = c(0.40, 0.55)) +
    labs(
      title   = "Taxa de exclusão do sistema de consórcios",
      x       = "Ano",
      y       = "Taxa de exclusão",
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
  params_row  <- manual_panorama_series %>% filter(year == latest_year)

  fee_auto    <- params_row$admin_fee_auto
  fee_housing <- params_row$admin_fee_housing
  if (fee_auto    <= 1) fee_auto    <- fee_auto    * 100
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
    rows  = NULL,
    theme = gridExtra::ttheme_minimal(
      core    = list(
        fg_params = list(fontsize = 10, fontfamily = "sans"),
        bg_params = list(fill = c("grey95", "white"))
      ),
      colhead = list(
        fg_params = list(fontsize = 11, fontface = "bold", fontfamily = "sans"),
        bg_params = list(fill = "grey80")
      )
    )
  )

  p3 <- ggplot() +
    xlim(0, 1) +
    ylim(0, 1) +
    annotation_custom(table_grob, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
    labs(
      title   = sprintf("Parâmetros das simulações — Consórcio (%d)", latest_year),
      caption = "Fonte: BCB — Panorama do Sistema de Consórcios"
    ) +
    theme_void(base_family = "sans") +
    theme(
      plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
      plot.caption    = element_text(size = 8, color = "grey50", hjust = 0),
      plot.margin     = margin(10, 10, 10, 10),
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

  # Paleta monocromática — adequada para impressão P&B
  # fig04/05/06: tons de cinza espaçados + borda escura
  # fig07:       tipo de linha + marcador
  scenario_grey <- c(
    "Consórcio (contemplação antecipada)"    = "grey15",
    "Consórcio (contemplação intermediária)" = "grey40",
    "Consórcio (contemplação tardia)"        = "grey62",
    "Financiamento bancário"                 = "grey82",
    "Acumulação autônoma"                    = "white"
  )

  scenario_linetype <- c(
    "Consórcio (contemplação antecipada)"    = "solid",
    "Consórcio (contemplação intermediária)" = "dashed",
    "Consórcio (contemplação tardia)"        = "dotted",
    "Financiamento bancário"                 = "longdash",
    "Acumulação autônoma"                    = "twodash"
  )
  scenario_shape <- c(
    "Consórcio (contemplação antecipada)"    = 16,
    "Consórcio (contemplação intermediária)" = 17,
    "Consórcio (contemplação tardia)"        = 15,
    "Financiamento bancário"                 = 18,
    "Acumulação autônoma"                    = 4
  )

  # ── Gráfico 4: Custo total desembolsado ────────────────────────────────────
  p4 <- sim_data %>%
    ggplot(aes(x = asset_pt, y = total_cost, fill = scenario_pt)) +
    geom_col(
      position  = position_dodge(width = 0.8),
      width     = 0.7,
      colour    = "grey10",
      linewidth = 0.3
    ) +
    scale_fill_manual(values = scenario_grey, name = "Cenário") +
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
    geom_col(
      position  = position_dodge(width = 0.8),
      width     = 0.7,
      colour    = "grey10",
      linewidth = 0.3
    ) +
    scale_fill_manual(values = scenario_grey, name = "Cenário") +
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
  opp_data <- sim_data %>%
    mutate(opp_direction = ifelse(opportunity_cost < 0, "Favorável", "Desfavorável"))

  p6 <- opp_data %>%
    ggplot(aes(x = scenario_pt, y = opportunity_cost, fill = opp_direction)) +
    geom_col(
      width     = 0.6,
      colour    = "grey10",
      linewidth = 0.3
    ) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey30", linewidth = 0.5) +
    coord_flip() +
    facet_wrap(~ asset_pt, scales = "free_x", ncol = 1) +
    scale_fill_manual(
      values = c("Favorável" = "grey82", "Desfavorável" = "grey30"),
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

    contemplation_lines <- simulation_results %>%
      filter(scenario %in% c("consortium_early", "consortium_mid", "consortium_late")) %>%
      mutate(
        scenario_pt = factor(scenario_labels_pt[as.character(scenario)],
                             levels = scenario_labels_pt[scenario_levels]),
        asset_pt    = factor(asset_labels_pt[as.character(asset)],
                             levels = asset_labels_pt)
      ) %>%
      select(asset_pt, scenario_pt, months_until_acquisition)

    # Pontos de marcador a cada N meses para não poluir o gráfico
    marker_interval_vehicle <- 10
    marker_interval_housing <- 30
    cf_markers <- cf_data %>%
      mutate(interval = ifelse(as.character(asset_pt) == "Veículo",
                               marker_interval_vehicle,
                               marker_interval_housing)) %>%
      filter(month %% interval == 0)

    p7 <- cf_data %>%
      ggplot(aes(
        x        = month,
        y        = cumulative_cf,
        linetype = scenario_pt,
        shape    = scenario_pt
      )) +
      geom_line(linewidth = 0.7, color = "grey20") +
      geom_point(
        data      = cf_markers,
        aes(shape = scenario_pt),
        size      = 2,
        color     = "grey20",
        fill      = "white",
        stroke    = 0.8
      ) +
      geom_vline(
        data      = contemplation_lines,
        aes(xintercept = months_until_acquisition, linetype = scenario_pt),
        color     = "grey20",
        linewidth = 0.4,
        alpha     = 0.6
      ) +
      facet_wrap(~ asset_pt, scales = "free", ncol = 1) +
      scale_linetype_manual(values = scenario_linetype, name = "Cenário") +
      scale_shape_manual(values = scenario_shape, name = "Cenário") +
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
      guides(
        linetype = guide_legend(nrow = 2),
        shape    = guide_legend(nrow = 2)
      )

    outputs$graph7 <- save_dual_plot(p7, path(figure_dir, "fig07_fluxo_acumulado"), width = 9, height = 8)
    log_info("[viz] Gráfico 7 salvo: fig07_fluxo_acumulado")
  } else {
    log_info("[viz] simulation_cashflows não disponível, Gráfico 7 não gerado")
  }

  # ── Tabela 1: Síntese comparativa (gt) ─────────────────────────────────────
  # Substitui o painel fig08 (patchwork).
  # Exportada via gtsave() em PNG (300 dpi via zoom=2) e PDF.
  # Destaque por negrito — sem dependência de cor, adequado para impressão.
  #
  # Critérios de negrito por grupo de bem:
  #   custo_total / vp_custo : menor valor da coluna
  #   custo_opp              : valor mais favorável (mais negativo, excluindo referência)
  # ───────────────────────────────────────────────────────────────────────────

  # gt carregado via utils.R
  tbl_data <- simulation_results %>%
      mutate(
        scenario  = factor(scenario, levels = scenario_levels),
        mecanismo = scenario_labels_pt[as.character(scenario)],
        bem       = asset_labels_pt[as.character(asset)],
        custo_total = round(total_cost),
        vp_custo    = round(present_value_cost),
        custo_opp   = round(opportunity_cost),
        meses       = as.integer(months_until_acquisition),
        is_ref      = scenario == "autonomous_savings"
      ) %>%
      arrange(factor(asset, levels = c("vehicle", "housing")), scenario) %>%
      select(bem, mecanismo, custo_total, vp_custo, custo_opp, meses, is_ref)

    # Flags de negrito calculados antes da formatação
    bold_flags <- tbl_data %>%
      group_by(bem) %>%
      mutate(
        bold_total = custo_total == min(custo_total),
        bold_vp    = vp_custo    == min(vp_custo),
        bold_opp   = !is_ref & (custo_opp == min(custo_opp[!is_ref]))
      ) %>%
      ungroup()

    # Formatar valores para exibição
    tbl_fmt <- bold_flags %>%
      mutate(
        custo_total_fmt = format_brl(custo_total),
        vp_custo_fmt    = format_brl(vp_custo),
        custo_opp_fmt   = ifelse(is_ref, "— referência", format_opp(custo_opp)),
        meses_fmt       = paste0("mês ", meses)
      )

    tbl_gt <- tbl_fmt %>%
      select(bem, mecanismo, custo_total_fmt, vp_custo_fmt, custo_opp_fmt, meses_fmt) %>%
      gt(groupname_col = "bem") %>%

      cols_label(
        mecanismo       = "Mecanismo",
        custo_total_fmt = "Custo total",
        vp_custo_fmt    = "Valor presente",
        custo_opp_fmt   = "Custo de oportunidade",
        meses_fmt       = "Aquisição"
      ) %>%

      tab_header(
        title    = "Comparativo de eficiência econômica",
        subtitle = "Veículo (R$ 80.000) e imóvel (R$ 300.000)"
      ) %>%

      tab_footnote(
        footnote  = paste0(
          "Custo de oportunidade = valor futuro dos pagamentos − valor futuro do ativo adquirido. ",
          "Valores negativos indicam resultado favorável ao mecanismo. ",
          "Acumulação autônoma adotada como referência (custo de oportunidade = 0 por definição). ",
          "Taxa de desconto: Selic anual média."
        ),
        locations = cells_column_labels(columns = custo_opp_fmt)
      ) %>%

      tab_source_note(
        source_note = "Fonte: Elaboração própria com dados do BCB — Panorama do Sistema de Consórcios e SGS."
      ) %>%

      cols_align(align = "left",  columns = mecanismo) %>%
      cols_align(align = "right", columns = c(custo_total_fmt, vp_custo_fmt,
                                               custo_opp_fmt, meses_fmt)) %>%

      # Negrito: menor custo total por bem
      tab_style(
        style     = cell_text(weight = "bold"),
        locations = cells_body(
          columns = custo_total_fmt,
          rows    = bold_flags$bold_total
        )
      ) %>%
      # Negrito: menor VP por bem
      tab_style(
        style     = cell_text(weight = "bold"),
        locations = cells_body(
          columns = vp_custo_fmt,
          rows    = bold_flags$bold_vp
        )
      ) %>%
      # Negrito: custo de oportunidade mais favorável por bem
      tab_style(
        style     = cell_text(weight = "bold"),
        locations = cells_body(
          columns = custo_opp_fmt,
          rows    = bold_flags$bold_opp
        )
      ) %>%

      # Itálico + cinza na linha de referência
      tab_style(
        style     = cell_text(style = "italic", color = "grey50"),
        locations = cells_body(rows = bold_flags$is_ref)
      ) %>%

      # Linha separadora acima dos títulos de grupo
      tab_style(
        style     = cell_borders(sides = "top", color = "grey30", weight = px(1.5)),
        locations = cells_row_groups()
      ) %>%

      opt_table_font(font = list(google_font("Source Sans Pro"), default_fonts())) %>%
      tab_options(
        table.font.size                    = px(11),
        heading.title.font.size            = px(13),
        heading.subtitle.font.size         = px(11),
        column_labels.font.weight          = "bold",
        row_group.font.weight              = "bold",
        row_group.font.size                = px(12),
        table.border.top.style             = "none",
        table.border.bottom.style          = "none",
        column_labels.border.top.width     = px(1.5),
        column_labels.border.top.color     = "grey30",
        column_labels.border.bottom.width  = px(1),
        column_labels.border.bottom.color  = "grey60",
        stub.border.style                  = "none",
        source_notes.font.size             = px(9),
        footnotes.font.size                = px(9),
        data_row.padding                   = px(5)
      )

    png_path <- path(figure_dir, "fig08_sintese_comparativa.png")
    pdf_path <- path(figure_dir, "fig08_sintese_comparativa.pdf")

    tryCatch({
      gt::gtsave(tbl_gt, filename = png_path, zoom = 2, expand = 10)
      log_info("[viz] Tabela 1 salva: fig08_sintese_comparativa.png")
    }, error = function(e) {
      log_info(sprintf("[viz] Erro ao salvar PNG da tabela gt: %s", conditionMessage(e)))
    })

    tryCatch({
      gt::gtsave(tbl_gt, filename = pdf_path)
      log_info("[viz] Tabela 1 salva: fig08_sintese_comparativa.pdf")
    }, error = function(e) {
      log_info(sprintf("[viz] Erro ao salvar PDF da tabela gt: %s", conditionMessage(e)))
    })

    outputs$table1 <- list(png = png_path, pdf = pdf_path)
    log_info("[viz] Tabela 1 concluída: fig08_sintese_comparativa")

  invisible(outputs)
}