# R Pipeline: Economic Efficiency of Consortium in Brazil

This repository contains a **fully reproducible data pipeline in R** used to analyze the **economic efficiency of the consortium system in Brazil**, compared with:

1. Bank financing
2. Autonomous capital accumulation (savings)

The pipeline downloads public data, processes it, constructs analytical datasets, runs comparative simulations, and generates figures used in the research.

The analysis relies primarily on **institutional data sources**, especially the **Central Bank of Brazil (BCB)** and the **IBGE SIDRA system**.

---

# Pipeline Structure

The project follows a modular pipeline architecture:

project/
│
├─ run_pipeline.R
│
├─ scripts/
│   ├─ utils.R
│   ├─ ingestion.R
│   ├─ processing.R
│   ├─ transformation.R
│   └─ visualization.R
│
├─ data/
│   ├─ raw/
│   ├─ interim/
│   ├─ processed/
│   └─ manual/
│
└─ figures/

### Module description

| Script | Purpose |
|------|------|
| utils.R | Utility helpers (logging, safe execution, numeric cleaning, plotting utilities) |
| ingestion.R | Download and persistence of raw datasets |
| processing.R | Data cleaning, harmonization, and provenance metadata |
| transformation.R | Analytical tables and simulation scenarios |
| visualization.R | Generation of article-ready figures |
| run_pipeline.R | Main orchestration script |

---

# Execution Instructions

## 1. Install R dependencies

Run in R:

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

---

## 2. Run the pipeline

From the repository root:

Rscript project/run_pipeline.R

The script executes the following steps:

1. Directory initialization
2. Data ingestion (BCB Open Data, SGS, SIDRA)
3. Data cleaning and harmonization
4. Construction of analytical datasets
5. Economic simulation of acquisition scenarios
6. Generation of figures

---

# Outputs

After execution, the pipeline generates:

## Processed datasets

Location:

project/data/processed/

Files generated:

annual_consorcio_summary.csv
monthly_credit_parameters.csv
macro_parameters.csv
manual_panorama_series.csv
simulation_results.csv
simulation_cashflows.csv

---

## Figures

Location:

project/figures/

Figures include:

1. Active consortium quotas in Brazil
2. Consortium exclusion rate
3. Administrative fees by consortium segment
4. Average consortium term by segment
5. Financing rates (vehicle vs housing)
6. Total cost comparison (vehicle)
7. Total cost comparison (housing)
8. Time to acquisition comparison (vehicle)
9. Time to acquisition comparison (housing)
10. Opportunity cost comparison (vehicle)
11. Opportunity cost comparison (housing)
12. Sensitivity analysis

Figures are exported as:

PNG (high resolution)
PDF (vector format for academic publication)

---

# Data Sources

The pipeline relies on publicly available institutional data.

### Central Bank of Brazil (BCB)

BCB Open Data Portal:

https://dadosabertos.bcb.gov.br

Used datasets include:

- Active consortium quotas
- Excluded quotas
- Consortium exclusion index

---

### BCB SGS (Time Series System)

Accessed via the **rbcb R package**.

Series used:

| SGS Code | Description |
|------|------|
| 25471 | Vehicle financing interest rate |
| 20886 | Average vehicle financing term |
| 25497 | Housing financing interest rate |
| 20912 | Average housing financing term |
| 432 | Selic interest rate |

---

### IBGE SIDRA

Inflation data (IPCA)

SIDRA table:

1737

Accessed through the **sidrar R package**.

---

# Manual Data Requirement

The **BCB Panorama Consortium reports** are published as PDF documents.

Because these reports **do not provide a stable tabular API**, the pipeline includes a manual extraction step.

The pipeline automatically generates a template file:

project/data/manual/manual_panorama_series_template.csv

You must manually fill this file using data extracted from Panorama reports (for example: 2022, 2023, 2024).

Required fields:

| Field | Description |
|------|------|
| year | Reference year |
| admin_fee_total | Average administrative fee (total market) |
| avg_term_total | Average consortium term (total) |
| admin_fee_auto | Administrative fee – vehicle consortium |
| avg_term_auto | Average term – vehicle consortium |
| admin_fee_housing | Administrative fee – housing consortium |
| avg_term_housing | Average term – housing consortium |

Also fill provenance metadata:

| Field | Description |
|------|------|
| source_dataset | Example: "BCB Panorama Consortium 2023" |
| source_url | Link to the Panorama report |
| note | Any clarification or observation |

---

# Reproducibility

The pipeline was designed to support **fully reproducible empirical research**.

Key principles:

- deterministic pipeline execution
- raw data persistence
- explicit provenance metadata
- automated figure generation
- modular processing steps

All intermediate datasets are stored in the repository structure.

---

# Important Notes

1. If BCB changes the structure of Open Data datasets, update the ingestion functions.

2. If SGS codes change, update:

config$sgs_codes

in:

project/run_pipeline.R

3. Manual Panorama data must be updated whenever new reports are published.

---

# License

This repository is intended for **academic research and reproducible economic analysis**.

# Processed Datasets Documentation

## 1. Visão geral dos datasets processados

Esta seção documenta os datasets finais gerados em `project/data/processed/`, utilizados nas simulações e na análise do estudo **Economic Efficiency of Consorcio in Brazil**. O objetivo é garantir rastreabilidade metodológica, reprodutibilidade e vínculo explícito com fontes institucionais.

Os arquivos documentados são:

- `annual_consorcio_summary.csv`
- `macro_parameters.csv`
- `manual_panorama_series.csv`
- `monthly_credit_parameters.csv`
- `simulation_cashflows.csv`
- `simulation_results.csv`

**Prioridade institucional de fontes no pipeline** (conforme configuração do projeto):
1. Banco Central do Brasil (BCB)
2. IBGE
3. OECD *(não utilizada nesta etapa de datasets processados)*
4. World Bank *(não utilizada nesta etapa de datasets processados)*

---

## 2. Documentação dos datasets

### 2.1 `annual_consorcio_summary.csv`

**Dataset name**
`annual_consorcio_summary.csv`

**Purpose in the research**
Consolidar, em frequência anual, o estoque médio de cotas ativas e o índice médio de exclusão de consórcio, para uso em análise descritiva e visualizações históricas.

**Pipeline stage where it is created**
- Transformação (`build_annual_consorcio_summary()` em `project/scripts/transformation.R`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `Year` | inteiro | Ano de referência derivado de `date` (dados mensais agregados por média). |
| `ActiveQuotas` | numérico | Média anual de `active_quotas` (cotas ativas). |
| `ExclusionRate` | numérico | Média anual de `exclusion_rate` (índice/taxa de exclusão). |

**Source dataset or document**
- Dataset CKAN BCB: `27459-cotas-ativas-por-tipo-de-administradora---total`
- Dataset CKAN BCB: `27488-indice-de-exclusao-por-tipo-de-bem---consolidado`

**Institutional source**
Banco Central do Brasil (BCB), portal de Dados Abertos.

**Document title**
Títulos de datasets CKAN do BCB conforme slug público das URLs acima.

**Page number (if applicable)**
Não aplicável (extração via API/arquivo tabular, sem paginação de relatório PDF).

**Official link**
- https://dadosabertos.bcb.gov.br/dataset/27459-cotas-ativas-por-tipo-de-administradora---total
- https://dadosabertos.bcb.gov.br/dataset/27488-indice-de-exclusao-por-tipo-de-bem---consolidado

**Extraction method (API or manual extraction)**
API/automático (CKAN do BCB + download de recurso CSV/TXT).

**Notes about transformations or limitations**
- Conversão e padronização de colunas com limpeza de nomes e parsing robusto de data.
- Seleção automática de coluna de valor com regras por candidatos.
- Se `exclusion_rate` vier em escala percentual (>1), o pipeline divide por 100.
- Agregação anual por média simples dos valores mensais.

---

### 2.2 `macro_parameters.csv`

**Dataset name**
`macro_parameters.csv`

**Purpose in the research**
Disponibilizar parâmetros macrofinanceiros mensais (juros de crédito + inflação IPCA + Selic opcional) para interpretação econômica e suporte às simulações.

**Pipeline stage where it is created**
- Transformação (`build_macro_parameters()`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `date` | data (`YYYY-MM-DD`) | Data de referência mensal. |
| `vehicle_interest_rate` | numérico | Taxa mensal de juros para crédito de veículos (SGS). |
| `housing_interest_rate` | numérico | Taxa mensal de juros para crédito habitacional (SGS). |
| `ipca_monthly` | numérico | Série mensal de IPCA obtida da Tabela SIDRA 1737 (campo de valor da extração). |
| `selic_rate` | numérico/NA | Taxa Selic; pode ficar `NA` nesta etapa (série opcional). |

**Source dataset or document**
- API SGS/BCB (séries mensais de crédito): códigos 25471, 20886, 25497, 20912
- SIDRA/IBGE: Tabela 1737 (variável 2266 no endpoint utilizado pelo pipeline)

**Institutional source**
Banco Central do Brasil (BCB) e IBGE (SIDRA).

**Document title**
- Sistema Gerenciador de Séries Temporais (SGS) do BCB
- Tabela SIDRA 1737 (IBGE)

**Page number (if applicable)**
Não aplicável (extração via API/tabular).

**Official link**
- https://api.bcb.gov.br
- https://sidra.ibge.gov.br/tabela/1737

**Extraction method (API or manual extraction)**
API/automático.

**Notes about transformations or limitations**
- Junção por `date` entre dados de crédito e IPCA.
- `selic_rate` é opcional e pode não estar disponível para toda a janela histórica; quando ausente, coluna é criada com `NA`.
- O dataset privilegia compatibilidade de janela mensal longa (desde 2012 na configuração padrão).

---

### 2.3 `manual_panorama_series.csv`

**Dataset name**
`manual_panorama_series.csv`

**Purpose in the research**
Registrar séries anuais extraídas manualmente dos relatórios Panorama de Consórcio do BCB (taxas administrativas e prazos médios), usadas para parametrização de cenários de consórcio.

**Pipeline stage where it is created**
- Ingestão: criação de template (`create_manual_panorama_template()`)
- Processamento: leitura/normalização (`process_manual_panorama()`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `year` | inteiro | Ano de referência do relatório/manual. |
| `admin_fee_total` | numérico | Taxa administrativa média do mercado total (%). |
| `avg_term_total` | numérico | Prazo médio do mercado total (meses). |
| `admin_fee_auto` | numérico | Taxa administrativa média para consórcio de automóveis (%). |
| `avg_term_auto` | numérico | Prazo médio para consórcio de automóveis (meses). |
| `admin_fee_housing` | numérico | Taxa administrativa média para consórcio imobiliário (%). |
| `avg_term_housing` | numérico | Prazo médio para consórcio imobiliário (meses). |
| `source_dataset` | texto | Nome exato do relatório/documento utilizado na extração manual. |
| `source_url` | texto | Link oficial do relatório usado. |
| `note` | texto | Campo livre para observações metodológicas (ex.: página de extração). |

**Source dataset or document**
Relatórios “Panorama do Sistema de Consórcios” do BCB (preenchimento manual pelo pesquisador a partir de PDFs oficiais).

**Institutional source**
Banco Central do Brasil (BCB).

**Document title**
Deve ser informado exatamente em `source_dataset` a cada linha (ex.: edição anual específica do Panorama).

**Page number (if applicable)**
Obrigatório registrar no campo `note` quando o valor vier de relatório paginado. No estado atual do arquivo processado, não há linhas preenchidas; portanto, não há páginas registradas.

**Official link**
https://www.bcb.gov.br/estabilidadefinanceira/panoramaconsorcio

**Extraction method (API or manual extraction)**
Extração manual.

**Notes about transformations or limitations**
- O pipeline apenas tipa/converte colunas; não infere conteúdo ausente.
- Sem preenchimento manual, as simulações usam parâmetros default de taxa administrativa.
- Este é o único dataset processado cuja proveniência detalhada depende de input humano.

---

### 2.4 `monthly_credit_parameters.csv`

**Dataset name**
`monthly_credit_parameters.csv`

**Purpose in the research**
Fornecer painel mensal de parâmetros de crédito para alimentar a simulação (taxas e prazos de financiamento para veículos e habitação).

**Pipeline stage where it is created**
- Processamento (`process_credit_and_selic_raw()`)
- Transformação leve (`build_monthly_credit_parameters()`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `date` | data (`YYYY-MM-DD`) | Data de referência mensal. |
| `vehicle_interest_rate` | numérico | Taxa de juros mensal para financiamento de veículos (SGS 25471). |
| `vehicle_term_months` | numérico | Prazo médio (meses) para financiamento de veículos (SGS 20886). |
| `housing_interest_rate` | numérico | Taxa de juros mensal para financiamento habitacional (SGS 25497). |
| `housing_term_months` | numérico | Prazo médio (meses) para financiamento habitacional (SGS 20912). |
| `source_dataset` | texto | Identificador da origem institucional da série (`BCB SGS`). |
| `source_url` | texto | URL institucional da fonte (`https://www.bcb.gov.br`). |

**Source dataset or document**
API SGS do BCB (códigos 25471, 20886, 25497, 20912).

**Institutional source**
Banco Central do Brasil (BCB).

**Document title**
Sistema Gerenciador de Séries Temporais (SGS).

**Page number (if applicable)**
Não aplicável.

**Official link**
https://api.bcb.gov.br

**Extraction method (API or manual extraction)**
API/automático.

**Notes about transformations or limitations**
- Parsing tolerante de payload CSV do SGS (`;` ou `,`).
- Conversão de `date` e cast numérico das séries.
- Ordenação cronológica crescente.

---

### 2.5 `simulation_cashflows.csv`

**Dataset name**
`simulation_cashflows.csv`

**Purpose in the research**
Armazenar o fluxo de caixa mensal sintético por cenário e por ativo, permitindo análises de trajetória de pagamentos.

**Pipeline stage where it is created**
- Simulação (`run_simulations()` / `simulate_asset()`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `asset` | texto | Tipo de ativo simulado (`vehicle` ou `housing`). |
| `scenario` | texto | Cenário: `consortium_early`, `consortium_mid`, `consortium_late`, `financing`, `autonomous_savings`. |
| `month` | inteiro | Índice do mês no fluxo de pagamentos (`1..n_payments`). |
| `monthly_cash_flow` | numérico | Valor mensal de desembolso simulado. |

**Source dataset or document**
Derivado computacionalmente de `monthly_credit_parameters.csv`, `manual_panorama_series.csv` e parâmetros fixados em `config$simulation`.

**Institutional source**
Não é extração institucional direta; deriva de modelos aplicados a insumos de BCB/IBGE.

**Document title**
Não aplicável (dataset sintético de simulação).

**Page number (if applicable)**
Não aplicável.

**Official link**
Não aplicável (resultado interno do pipeline).

**Extraction method (API or manual extraction)**
Geração algorítmica (não API/manual de fonte primária).

**Notes about transformations or limitations**
- Pagamento de financiamento calculado por fórmula de anuidade.
- Pagamento de poupança autônoma via inversão de valor futuro de anuidade.
- Pagamento de consórcio linear: `(valor_do_bem * (1 + taxa_admin)) / prazo_consórcio`.
- Taxa administrativa pode ser sobrescrita pelo último valor não nulo da série manual.

---

### 2.6 `simulation_results.csv`

**Dataset name**
`simulation_results.csv`

**Purpose in the research**
Consolidar métricas finais comparáveis entre estratégias de aquisição (consórcio, financiamento e poupança autônoma), por tipo de ativo.

**Pipeline stage where it is created**
- Simulação (`run_simulations()` / `simulate_asset()`)
- Persistido em `project/run_pipeline.R`

**Columns description**

| Coluna | Tipo esperado | Descrição técnica |
|---|---|---|
| `asset` | texto | Tipo de ativo simulado (`vehicle` ou `housing`). |
| `scenario` | texto | Cenário comparado. |
| `total_cost` | numérico | Soma nominal dos pagamentos (`monthly_cash_flow * n_payments`). |
| `present_value_cost` | numérico | Valor presente dos fluxos descontados pela taxa anual de desconto convertida para mensal. |
| `months_until_acquisition` | inteiro | Tempo até aquisição no cenário (meses). |
| `opportunity_cost` | numérico | `present_value_cost - asset_value`. |
| `monthly_cash_flow` | numérico | Pagamento mensal do cenário. |

**Source dataset or document**
Derivado computacionalmente de `monthly_credit_parameters.csv`, `manual_panorama_series.csv` e parâmetros de configuração do pipeline.

**Institutional source**
Não é extração institucional direta; resultado de modelagem aplicada.

**Document title**
Não aplicável (dataset sintético de resultado).

**Page number (if applicable)**
Não aplicável.

**Official link**
Não aplicável.

**Extraction method (API or manual extraction)**
Geração algorítmica.

**Notes about transformations or limitations**
- Usa a observação mais recente disponível de crédito mensal; se ausente, aplica parâmetros de fallback.
- Cenários de consórcio usam três tempos de contemplação (precoce/intermediário/tardio).
- Resultados dependem integralmente dos parâmetros em `config$simulation`.

---

## 3. Notas de rastreabilidade e reprodutibilidade

1. **Rastreabilidade de origem**: datasets oriundos de BCB/IBGE carregam campos de proveniência (`source_dataset`, `source_url`) quando disponíveis na estrutura da tabela processada.
2. **Reprodutibilidade determinística**: a sequência ingestão → processamento → transformação → simulação é orquestrada por `project/run_pipeline.R`, com escrita explícita dos seis arquivos processados.
3. **Documentação de extração manual**: para `manual_panorama_series.csv`, a reprodutibilidade requer preenchimento explícito de documento, URL e página (no campo `note`) para cada observação anual.
4. **Limitações declaradas**: séries opcionais (ex.: Selic diária) podem ficar ausentes por restrições de janela da API; o pipeline mantém execução e sinaliza ausência em coluna dedicada.
5. **Escopo de fontes nesta etapa**: não há ingestão de OECD e World Bank na etapa de datasets processados atual; sua inclusão exigirá extensão do módulo de ingestão e atualização desta documentação.
