# Pipeline em R: Eficiência Econômica do Consórcio no Brasil

Este repositório contém um **pipeline de dados totalmente reproduzível em R** para analisar a **eficiência econômica do sistema de consórcio no Brasil**, em comparação com:

1. Financiamento bancário
2. Acumulação autônoma de capital (poupança)

O pipeline realiza download de dados públicos, processa as bases, constrói conjuntos analíticos, executa simulações comparativas e gera as figuras utilizadas na pesquisa.

A análise se apoia principalmente em **fontes institucionais**, com destaque para o **Banco Central do Brasil (BCB)** e o **sistema SIDRA do IBGE**.

---

# Estrutura do Pipeline

O projeto segue uma arquitetura modular de pipeline:

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

### Descrição dos módulos

| Script | Finalidade |
|------|------|
| utils.R | Funções utilitárias (logging, execução segura, limpeza numérica, utilitários de visualização) |
| ingestion.R | Download e persistência das bases de dados brutas |
| processing.R | Limpeza, harmonização e metadados de proveniência |
| transformation.R | Tabelas analíticas e cenários de simulação |
| visualization.R | Geração de figuras prontas para artigo científico |
| run_pipeline.R | Script principal de orquestração |

---

# Instruções de Execução

## 1. Instalar dependências do R

Execute no R:

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

## 2. Executar o pipeline

Na raiz do repositório:

Rscript project/run_pipeline.R

O script executa as etapas abaixo:

1. Inicialização de diretórios
2. Ingestão de dados (BCB Open Data, SGS, SIDRA)
3. Limpeza e harmonização dos dados
4. Construção de datasets analíticos
5. Simulação econômica de cenários de aquisição
6. Geração de figuras

---

# Saídas

Após a execução, o pipeline gera:

## Datasets processados

Local:

project/data/processed/

Arquivos gerados:

annual_consorcio_summary.csv
monthly_credit_parameters.csv
macro_parameters.csv
manual_panorama_series.csv
simulation_results.csv
simulation_cashflows.csv

---

## Figuras

Local:

project/figures/

As figuras incluem:

1. Cotas ativas de consórcio no Brasil
2. Taxa de exclusão em consórcios
3. Taxas de administração por segmento de consórcio
4. Prazo médio de consórcio por segmento
5. Taxas de financiamento (veículos vs habitação)
6. Comparação de custo total (veículos)
7. Comparação de custo total (habitação)
8. Comparação do tempo até aquisição (veículos)
9. Comparação do tempo até aquisição (habitação)
10. Comparação de custo de oportunidade (veículos)
11. Comparação de custo de oportunidade (habitação)
12. Análise de sensibilidade

As figuras são exportadas em:

PNG (alta resolução)
PDF (formato vetorial para publicação acadêmica)

---

# Fontes de Dados

O pipeline utiliza dados institucionais de acesso público.

### Banco Central do Brasil (BCB)

Portal de Dados Abertos do BCB:

https://dadosabertos.bcb.gov.br

As bases utilizadas incluem:

- Cotas ativas de consórcio
- Cotas excluídas
- Índice de exclusão em consórcios

---

### BCB SGS (Sistema Gerenciador de Séries Temporais)

Acesso via pacote **rbcb** do R.

Séries utilizadas:

| Código SGS | Descrição |
|------|------|
| 25471 | Taxa de juros do financiamento de veículos |
| 20886 | Prazo médio do financiamento de veículos |
| 25497 | Taxa de juros do financiamento habitacional |
| 20912 | Prazo médio do financiamento habitacional |
| 432 | Taxa Selic |

---

### IBGE SIDRA

Dados de inflação (IPCA)

Tabela SIDRA:

1737

Acesso por meio do pacote **sidrar** do R.

---

# Requisito de Dados Manuais

Os relatórios **Panorama do Consórcio** do BCB são publicados em PDF.

Como esses relatórios **não disponibilizam uma API tabular estável**, o pipeline inclui uma etapa de extração manual.

O pipeline gera automaticamente um arquivo modelo:

project/data/manual/manual_panorama_series_template.csv

Você deve preencher manualmente esse arquivo com dados extraídos dos relatórios Panorama (por exemplo: 2022, 2023, 2024).

Campos obrigatórios:

| Campo | Descrição |
|------|------|
| year | Ano de referência |
| admin_fee_total | Taxa média de administração (mercado total) |
| avg_term_total | Prazo médio de consórcio (total) |
| admin_fee_auto | Taxa de administração – consórcio de veículos |
| avg_term_auto | Prazo médio – consórcio de veículos |
| admin_fee_housing | Taxa de administração – consórcio habitacional |
| avg_term_housing | Prazo médio – consórcio habitacional |

Também preencha os metadados de proveniência:

| Campo | Descrição |
|------|------|
| source_dataset | Exemplo: "BCB Panorama do Consórcio 2023" |
| source_url | Link para o relatório Panorama |
| note | Qualquer esclarecimento ou observação |
