# Fluxo de Caixa - Python + UV

## Visão Geral

Este projeto realiza a ingestão, validação e análise exploratória de um fluxo de caixa usando Python e PostgreSQL. O notebook `main.ipynb` importa quatro datasets em Excel, faz validações básicas, conecta-se a um banco PostgreSQL e carrega os dados em tabelas.

O arquivo `sql/postgresql.sql` documenta o pipeline de modelagem de dados, com estruturas de schemas `staging` e `dw`, transformações de tipos, criação de tabelas dimensionais e de fatos, e uma dimensão de calendário.

## Estrutura do Projeto

- `main.ipynb` - notebook com ingestão, EDA e conexão ao PostgreSQL.
- `pyproject.toml` - configurações do projeto e dependências.
- `dataset/` - pasta com os arquivos de entrada Excel.
- `sql/postgresql.sql` - script de modelagem e transformação SQL.
- `pbi/fluxo_caixa_python_uv_sql.pbix` - arquivo Power BI para relatórios e visualização.
- `README.md` - documentação do projeto.

## Dados

Os dados utilizados no notebook são:

- `dataset/Bancos.xlsx`
- `dataset/Movimentos.xlsx`
- `dataset/PlanoContas.xlsx`
- `dataset/SaldoAnterior.xlsx`

## Tecnologias e Dependências

- Python
- `uv` (gerenciador de pacotes)
- `pandas`
- `numpy`
- `openpyxl`
- `sqlalchemy`
- `psycopg2`
- `python-dotenv`

> Observação: o notebook usa `openpyxl` para ler arquivos Excel e `sqlalchemy` + `psycopg2` para conectar com PostgreSQL.

## Configuração do Ambiente

1. Inicializar o projeto com `uv`:
   ```bash
   uv init
   ```
2. Adicionar as dependências necessárias:
   ```bash
   uv add pandas
   uv add numpy
   uv add openpyxl
   uv add sqlalchemy psycopg2
   uv add python-dotenv
   ```

## Como Executar

1. Atualize o arquivo `.env` com a senha do PostgreSQL, por exemplo:
   ```env
   DB_PASSWORD=sua_senha_aqui
   ```
2. Execute `main.ipynb` em Jupyter ou JupyterLab.
3. No notebook, os DataFrames são carregados em tabelas PostgreSQL:
   - `bancos`
   - `plano_contas`
   - `movimentos`
   - `saldo_anterior`

4. Use `sql/postgresql.sql` para criar os schemas e tabelas de staging/dw e aplicar transformações adicionais.

## Notebook: principais etapas

1. Importar bibliotecas Python.
2. Ler os arquivos Excel em `dataset/`.
3. Criar DataFrames para cada dataset.
4. Verificar estrutura, tipos, nulos, duplicados e descrições das colunas.
5. Conectar ao banco PostgreSQL usando `sqlalchemy` e `python-dotenv`.
6. Gravar dados em tabelas no banco com `DataFrame.to_sql()`.

## Pipeline SQL

O script `sql/postgresql.sql` cobre o seguinte fluxo:

- Visualização inicial das tabelas brutas no schema `public`.
- Criação dos schemas `staging` e `dw`.
- Cópia das tabelas brutas para `staging`.
- Limpeza e repopulação de `st_movimentos`.
- Alteração de tipos de dados em colunas relevantes:
  - `Banco_ID` em `st_bancos`
  - `Subgrupo_ID` e `Conta_ID` em `st_plano_contas`
  - `Banco_ID` e `Valor` em `st_saldo_anterior`
  - `Data` e `Valor` em `st_movimentos`
- Criação de `st_movimentos_new` com chaves substituindo os campos textuais `Banco` e `Conta`.
- Criação das tabelas `dw.dim_bancos`, `dw.dim_plano_contas` e `dw.ft_saldo_anterior`.
- Definição de chaves primárias e estrangeiras.
- Criação e população da dimensão de tempo `dw.dim_calendario`.

## Modelagem de Dados

A modelagem desenvolvida no script SQL envolve três camadas principais:

- `public` (dados brutos)
  - `bancos`
  - `plano_contas`
  - `movimentos`
  - `saldo_anterior`

- `staging` (dados tratados e preparados)
  - `st_bancos`
  - `st_plano_contas`
  - `st_movimentos`
  - `st_saldo_anterior`
  - `st_movimentos_new`

- `dw` (data warehouse simplificado)
  - `dim_bancos`
  - `dim_plano_contas`
  - `ft_saldo_anterior`
  - `dim_calendario`

### Diagrama de Modelagem

```text
public                         staging                           dw
+------------+                +-------------+                  +-------------+
| bancos     | --------------> | st_bancos   | ---------------> | dim_bancos  |
+------------+                +-------------+                  | PK Banco_ID |
                                                            +-------------+

+----------------+          +----------------+                 +-------------------+
| plano_contas   | --------> | st_plano_contas| --------------> | dim_plano_contas |
+----------------+          +----------------+                 | PK Conta_ID      |
                                                                  +-------------------+

+-------------+             +---------------+ --------------+    +---------------------+
| movimentos  | ----------> | st_movimentos |               |    | ft_saldo_anterior   |
+-------------+             +---------------+               +--> | PK Saldo_ID        |
                                                              |    | FK Banco_ID       |
+----------------+          +----------------+               |    | Valor, Data       |
| saldo_anterior | --------> | st_saldo_anterior| ------------+    +---------------------+
+----------------+          +----------------+

                                            +------------------+
                                            | st_movimentos_new|
                                            +------------------+
                                                   |
                                                   | Conta_ID, Banco_ID
                                                   v
                                          (base para fatos futuros)

+------------------+                                     +-------------------+
| dim_calendario   | <-----------------------------------| ft_saldo_anterior |
+------------------+                                     +-------------------+
| PK data_id       |
| data             |
| nr_ano           |
| nr_mes           |
| nr_dia           |
+------------------+
```

### Tabelas e relacionamentos

- `dw.dim_bancos`
  - Chave primária: `Banco_ID`

- `dw.dim_plano_contas`
  - Chave primária: `Conta_ID`

- `dw.ft_saldo_anterior`
  - Chave primária: `Saldo_ID`
  - Chave estrangeira: `Banco_ID` → `dw.dim_bancos(Banco_ID)`

- `st_movimentos_new`
  - Contém `Banco_ID` e `Conta_ID` em vez dos valores textuais `Banco` e `Conta`
  - Serve como base para montar fatos de movimento com chaves consolidadas

- `dw.dim_calendario`
  - Dimensão de tempo com atributos como `data`, `nr_ano`, `nr_mes`, `nr_dia`, `nr_trimestre`, `nr_semana_ano`, `nr_dia_semana`, `nr_dia_ano`, `nm_dia_semana`, `nm_mes`, e `nr_ano_mes`

### Observações de modelagem

- A camada `staging` é usada para limpar e padronizar os dados antes da modelagem final.
- A camada `dw` contém dimensões e fatos que permitem análises históricas e financeiras.
- O uso de chaves numéricas (`Banco_ID`, `Conta_ID`) melhora a consistência e facilita joins entre tabelas.

## Objetivo

Oferecer um fluxo integrado de análise de fluxo de caixa, desde a ingestão dos arquivos Excel até a modelagem básica de dados em PostgreSQL. O projeto serve de base para criação de relatórios financeiros, dashboards e evolução para um data warehouse simples.

## Observações

- O notebook contém caminhos absolutos de arquivos Excel; ajuste-os se você mover o projeto para outro diretório.
- A documentação SQL complementa a etapa de ingestão com uma camadas de staging e data warehouse.
- O foco está em clareza, qualidade de dados e preparação para análises financeiras posteriores.
