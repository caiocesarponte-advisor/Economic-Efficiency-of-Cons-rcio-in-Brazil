# RESEARCH_METHOD.md
Research Methodology for Consórcio Efficiency Analysis

---

# 1. Objective

Definir o modelo metodológico que será utilizado para analisar a eficiência econômica do consórcio no Brasil.

O método deve permitir:

- replicação por outros pesquisadores
- comparação objetiva entre mecanismos financeiros
- análise baseada em dados verificáveis

---

# 2. Research Design

Tipo de estudo:

Comparative Economic Analysis

Abordagem:

Quantitative + Documentary

Método central:

Comparação entre três mecanismos de aquisição:

1. Consórcio
2. Financiamento
3. Acumulação própria de capital

---

# 3. Analytical Framework

O estudo avalia eficiência econômica com base em cinco dimensões:

1. Custo total
2. Tempo até aquisição do bem
3. Liquidez
4. Previsibilidade
5. Custo de oportunidade

---

# 4. Study Cases

Serão analisados dois bens:

## Case A

Imóvel residencial

Valor de referência:

R$ 300.000

---

## Case B

Automóvel

Valor de referência:

R$ 80.000

---

# 5. Scenario Definitions

Para cada bem serão simulados três cenários.

---

## Scenario 1 – Consórcio

Variáveis:

CartaCredito
PrazoMeses
TaxaAdministracao
FundoReserva
TempoContemplacao

Observação:

Serão simulados três cenários:

- contemplação inicial
- contemplação média
- contemplação tardia

---

## Scenario 2 – Financiamento

Variáveis:

ValorFinanciado
TaxaJuros
PrazoMeses
PrestacaoMensal

A aquisição ocorre no início do contrato.

---

## Scenario 3 – Poupança Autônoma

Variáveis:

AporteMensal
TaxaRetorno
TempoAcumulacao

A aquisição ocorre quando o capital acumulado atinge o valor do bem.

---

# 6. Core Economic Formulas

---

## 6.1 Total Cost

Custo total de cada mecanismo:

TotalCost = Sum(AllPayments)

---

## 6.2 Present Value

Para comparar fluxos financeiros ao longo do tempo:

PV = Σ (Payment_t / (1+r)^t)

onde:

r = taxa de desconto

---

## 6.3 Opportunity Cost

Custo de oportunidade da espera:

OpportunityCost = InvestmentValue - ActualValue

---

## 6.4 Capital Accumulation

Acumulação de capital com aportes mensais:

FV = P * ((1+i)^n - 1) / i

onde:

P = aporte mensal  
i = taxa de retorno  
n = número de períodos

---

# 7. Data Sources

Os parâmetros devem ser extraídos de:

Banco Central do Brasil  
IBGE  
IPEA  
dados de crédito imobiliário  
dados de crédito automotivo

---

# 8. Simulation Model

Cada mecanismo será simulado com os seguintes outputs:

TotalCost

TimeToAcquisition

NetPresentCost

OpportunityCost

---

# 9. Comparative Metrics

Os três mecanismos serão comparados por:

Custo total pago

Tempo até aquisição

Flexibilidade financeira

Liquidez

Previsibilidade

---

# 10. Statistical Tools

Ferramenta principal:

R

Pacotes:

ggplot2  
dplyr  
readxl

---

# 11. Simulation Workflow

1. coletar dados reais
2. definir parâmetros
3. criar simulações
4. gerar gráficos
5. interpretar resultados

---

# 12. Robustness Check

Para evitar conclusões frágeis, serão realizados:

Sensitivity Analysis

Testes com diferentes taxas:

juros  
inflação  
rentabilidade

---

# 13. Limitations

O modelo assume:

parâmetros médios de mercado

Resultados podem variar conforme:

contrato específico  
condições de crédito  
perfil do consumidor

---

# 14. Replication Principle

Qualquer pesquisador deve ser capaz de:

- acessar os dados
- executar os scripts
- reproduzir os gráficos

---

# 15. Scientific Integrity

Todas as conclusões devem derivar de:

dados

simulações

comparação objetiva

Não serão utilizadas afirmações sem evidência empírica./
