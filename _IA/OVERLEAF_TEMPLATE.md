# OVERLEAF_TEMPLATE.md
Scientific Article Structure (abnTeX2)

---

# 1. Objective

Definir a estrutura do artigo científico em LaTeX utilizando abnTeX2 conforme normas ABNT.

---

# 2. Project Structure

project/

main.tex  
references.bib  
figures/  
data/  

sections/

introduction.tex  
literature_review.tex  
methodology.tex  
results.tex  
discussion.tex  
conclusion.tex

---

# 3. Main File (main.tex)

Estrutura principal:

\documentclass[12pt,oneside]{article}

\usepackage{abntex2cite}
\usepackage{graphicx}

\title{Economic Efficiency of Consórcio in Brazil}
\author{Author Name}

\begin{document}

\maketitle

\input{sections/introduction}

\input{sections/literature_review}

\input{sections/methodology}

\input{sections/results}

\input{sections/discussion}

\input{sections/conclusion}

\bibliography{references}

\end{document}

---

# 4. Article Sections

## Introduction

Conteúdo:

- contextualização
- problema de pesquisa
- hipótese
- objetivos

---

## Literature Review

Conteúdo:

- funcionamento do sistema de consórcios
- estudos comparativos
- conceitos de eficiência econômica

---

## Methodology

Conteúdo:

- tipo de pesquisa
- base de dados
- variáveis analisadas
- modelo comparativo

---

## Results

Conteúdo:

- gráficos
- tabelas
- análise quantitativa

---

## Discussion

Conteúdo:

- interpretação dos resultados
- confronto com literatura
- limitações do estudo

---

## Conclusion

Conteúdo:

- resposta ao problema de pesquisa
- confirmação ou rejeição da hipótese
- sugestões de pesquisa futura

---

# 5. Bibliography

Arquivo:

references.bib

Exemplo:

@article{bcb2023,
title={Panorama do Sistema de Consórcios},
author={Banco Central do Brasil},
year={2023}
}

---

# 6. Figures

Inserção padrão:

\begin{figure}[h]
\centering
\includegraphics[width=0.8\textwidth]{figures/graph1_active_quotas.png}
\caption{Evolution of Active Consórcio Quotas}
\end{figure}

---

# 7. Citation Style

ABNT.

Gerenciado via:

abntex2cite + BibTeX.

---

# 8. Compilation

Compilar no Overleaf com:

pdflatex
bibtex
pdflatex
pdflatex

---

# 9. Reproducibility

Todo gráfico deve possuir:

- script em R
- dataset identificado
- referência da fonte

---

# 10. Final Principle

O artigo deve ser reproduzível e baseado em evidências.

Qualquer pesquisador deve conseguir replicar os resultados.
