# Fluxo de Caixa - Python + UV

## Visão Geral

Este projeto realiza a ingestão e análise exploratória de um fluxo de caixa a partir de quatro bases de dados em Excel. A implementação é feita em Python com uso do gerenciador de pacotes `uv`, seguindo uma estrutura de projeto moderna e organizada.

## Estrutura do Projeto

- `main.ipynb` - notebook de análise e visualização dos dados.
- `pyproject.toml` - configurações do projeto e dependências.
- `data/` - pasta com os arquivos de entrada Excel.
- `README.md` - documentação do projeto.

## Dados

Os dados utilizados no notebook são:

- `data/Bancos.xlsx`
- `data/Movimentos.xlsx`
- `data/PlanoContas.xlsx`
- `data/SaldoAnterior.xlsx`

## Tecnologias e Dependências

- Python
- uv (gerenciador de pacotes)
- pandas
- numpy
- openpyxl

> Observação: `openpyxl` foi necessário para leitura de arquivos Excel a partir do notebook.

## Procedimento de Configuração

1. Inicializar o projeto com `uv`:
   ```bash
   uv init
   ```
2. Adicionar as dependências necessárias:
   ```bash
   uv add pandas
   uv add numpy
   uv add openpyxl
   ```

## Como Executar

- Executar o notebook `main.ipynb` em um ambiente Jupyter.

## Etapas de Análise

O notebook documenta as seguintes etapas:

1. Importação das bibliotecas.
2. Leitura dos arquivos Excel.
3. Criação de dataframes para cada dataset.
4. Verificação das primeiras linhas do dataframe (`.head()`).
4. Verificação de estrutura e tipos de dados (`.info()`).
5. Verificação de valores nulos (`.isnull().sum()`).
6. Verificação de valores duplicados (`.duplicated().sum()`).
7. Análise estatística de colunas numéricas (`.describe().round(2)`) e textuais (`.describe(include='object')`).

## Objetivo

Fornecer uma base organizada para análise de fluxo de caixa, garantindo integridade dos dados e permitindo evolução para dashboards, transformações ou relatórios financeiros.

## Observações

- O projeto foi desenvolvido com foco em clareza e em boas práticas de organização de dependências.
- O notebook é o principal artefato de demonstração da análise exploratória de dados.
