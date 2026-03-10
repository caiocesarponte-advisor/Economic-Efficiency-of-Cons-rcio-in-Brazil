# GRAPHS_PLAN.md
Scientific Visualization Plan

---

# 1. Objective

Definir os gráficos que serão produzidos para análise da eficiência econômica do consórcio.

Os gráficos devem:

- facilitar interpretação
- apoiar hipóteses
- basear-se em dados oficiais.

---

# 2. Graph Categories

## 2.1 Market Structure Graphs

### Graph 1
Evolution of Active Consórcio Quotas

Tipo:
Line chart

Variáveis:

Year
ActiveQuotas

Objetivo:

Mostrar crescimento ou retração do sistema.

---

### Graph 2
Contemplation vs Exclusion

Tipo:

Stacked bar chart

Variáveis:

ContemplatedQuotas
ExcludedQuotas

Objetivo:

Mostrar eficiência prática do sistema.

---

## 2.2 Cost Structure

### Graph 3
Average Administration Fee

Tipo:

Line chart

Variáveis:

Year
AdminFeeAverage

Objetivo:

Mostrar evolução do custo administrativo.

---

## 2.3 Time Structure

### Graph 4
Average Term of Consórcio Contracts

Tipo:

Line chart

Variáveis:

Segment
AverageTerm

Objetivo:

Mostrar horizonte temporal do sistema.

---

# 3. Comparative Efficiency Graphs

Esses gráficos serão produzidos por simulação.

---

### Graph 5
Total Cost Comparison

Tipo:

Bar chart

Comparação:

Consórcio
Financing
Savings

Variável:

TotalCost

---

### Graph 6
Time to Acquisition

Tipo:

Bar chart

Comparação:

Consórcio
Financing
Savings

Variável:

MonthsUntilAcquisition

---

### Graph 7
Opportunity Cost Simulation

Tipo:

Line chart

Comparação:

Investment Growth vs Consórcio Payments

Variáveis:

Time
CapitalAccumulated

---

# 4. Tools

Os gráficos devem ser produzidos em:

R

Pacotes recomendados:

ggplot2
dplyr
tidyr

---

# 5. Visualization Principles

Gráficos devem seguir boas práticas científicas:

- títulos claros
- eixos rotulados
- fonte do dado citada
- escalas consistentes

---

# 6. Export

Gráficos devem ser exportados em:

PDF
PNG

para inserção em LaTeX.

---

# 7. File Structure

figures/

graph1_active_quotas.png  
graph2_contemplation_exclusion.png  
graph3_admin_fee.png  
graph4_term_length.png  
graph5_cost_comparison.png  
graph6_time_acquisition.png  
graph7_opportunity_cost.png
