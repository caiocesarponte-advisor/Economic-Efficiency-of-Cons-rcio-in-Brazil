# Pesquisa: Eficiencia Economica do Consorcio no Brasil

Este repositrio documenta um pipeline de dados 100% reproduzivel em R para analisar a eficiencia economica do sistema de consorcio no Brasil, comparando:

1. Consorcio
2. Financiamento bancario
3. Acumulacao autonoma de capital (poupanca)

A analise e orientada por evidencia (fontes institucionais), compatibilidade com escrita academica em LaTeX (abnTeX2) e geracao de graficos prontos para publicacao.

---

# Como executar o pipeline (R)

## 1. Instalar dependencias

Execute no R:

```r
install.packages(c(
  "tidyverse",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "lubridate",
  "janitor",
  "purrr",
  "ggplot2",
  "scales",
  "jsonlite",
  "httr2",
  "sidrar",
  "rbcb",
  "fs",
  "here"
))
```

## 2. Rodar o script principal

Na raiz do repositorio:

```bash
Rscript run_pipeline.R
```

O pipeline orquestra ingestao, limpeza/harmonizacao, transformacoes analiticas, simulacoes e geracao de figuras.

---

# Dados manuais (Panorama do Consorcio - BCB)

Como os relatrios "Panorama do Consorcio" nao dispoem de uma API tabular estavel, ha uma etapa manual.

1. Preencha `data/manual/manual_panorama_series_template.csv`
2. Use dados extraidos dos relatorios (ex.: 2022, 2023, 2024)

Campos obrigatorios:

- `year`
- `admin_fee_total`
- `avg_term_total`
- `admin_fee_auto`
- `avg_term_auto`
- `admin_fee_housing`
- `avg_term_housing`

Metadados de proveniencia (obrigatorios para rastreabilidade):

- `source_dataset`
- `source_url`
- `note`

---

# Saidas geradas

## Dados processados

`data/processed/`

Arquivos gerados (principais):

- `annual_consorcio_summary.csv`
- `monthly_credit_parameters.csv`
- `macro_parameters.csv`
- `manual_panorama_series.csv`
- `simulation_results.csv`
- `simulation_cashflows.csv`

## Figuras

`figures/`

As figuras sao exportadas em:

- `PNG` (alta resolucao)
- `PDF` (vetorial, para publicacao academica)

---

# Integracao com o artigo (LaTeX + abnTeX2)

Sugestao de fluxo:

1. Use as saidas do pipeline para embasar tabelas, graficos e resultados.
2. Garanta que todas as afirmacoes quantitativas tenham citacao inline em formato autor-data ABNT.
3. Estruture o texto seguindo o modelo IMRAD adaptado (Introducao, Referencial Teorico, Trabalhos Correlatos, Metodologia, Resultados, Conclusao).

Os diretorios `sections/` e `tables/` existem no repositorio para voce organizar conteudo/trechos do manuscrito (quando voce desejar incorporar no Overleaf).
