# DATASET.md
Data Sources for Research on Consórcio Efficiency

---

# 1. Objective

Este documento lista as bases de dados que devem ser utilizadas no estudo sobre eficiência econômica do consórcio no Brasil.

Somente bases:

- verificáveis
- públicas
- institucionalmente confiáveis

devem ser utilizadas.

---

# 2. Primary Data Sources

## 2.1 Banco Central do Brasil

Principal fonte de dados sobre consórcios.

Base principal:

Panorama do Sistema de Consórcios

Dados disponíveis:

- cotas ativas
- cotas contempladas
- índice de exclusão
- taxa média de administração
- prazos médios
- volume financeiro

Fonte:
https://www.bcb.gov.br/estabilidadefinanceira/consorcios

Documento principal:

Panorama do Sistema de Consórcios.

---

## 2.2 Sistema Financeiro Nacional (BCB datasets)

Possíveis dados úteis:

- crédito imobiliário
- crédito automotivo
- taxas médias de financiamento
- inadimplência

Fonte:
https://dadosabertos.bcb.gov.br

---

# 3. Secondary Data Sources

## 3.1 IBGE

Usado para contextualização econômica.

Variáveis úteis:

- renda média
- inflação
- custo de vida
- distribuição de renda

Fonte:
https://sidra.ibge.gov.br

---

## 3.2 IPEA

Dados macroeconômicos e financeiros.

Fonte:
https://www.ipeadata.gov.br

---

## 3.3 FGV

Possíveis indicadores úteis:

- inflação
- índices econômicos
- crédito

Fonte:
https://portalibre.fgv.br

---

# 4. Academic Literature

Bases recomendadas:

Google Scholar  
https://scholar.google.com

SciELO  
https://scielo.org

CAPES  
https://catalogodeteses.capes.gov.br

---

# 5. Data Organization Structure

Os dados devem ser organizados em planilhas com as seguintes colunas:

Year
Segment
ActiveQuotas
ContemplatedQuotas
ExclusionRate
AdminFeeAverage
AverageTerm
TotalVolume

---

# 6. Data Quality Rules

Todos os dados utilizados devem:

- possuir fonte identificável
- possuir data de publicação
- permitir replicação

Dados sem origem institucional não devem ser utilizados.

---

# 7. Dataset Storage

Estrutura sugerida:

data/

consorcio_bcb.csv  
credit_rates.csv  
income_ibge.csv  
inflation_series.csv

---

# 8. Replicability

Toda análise deve permitir replicação por outro pesquisador.

Portanto:

- scripts devem ser documentados
- datasets devem citar origem
- transformações devem ser registradas.
