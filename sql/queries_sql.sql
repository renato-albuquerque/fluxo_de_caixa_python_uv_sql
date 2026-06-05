-- Visualizar tabelas db_cash_flow_uv, schema public (Raw data). Tabelas ok.
SELECT * FROM public.bancos;
SELECT * FROM public.movimentos;
SELECT * FROM public.plano_contas;
SELECT * FROM public.saldo_anterior;

-- Criar schema staging e dw (data warehouse).
CREATE SCHEMA staging;
CREATE SCHEMA dw;

-- Copiar tabelas do schema public (Raw data) para o schema staging.
CREATE TABLE staging.st_bancos AS TABLE public.bancos;
CREATE TABLE staging.st_movimentos AS TABLE public.movimentos;
CREATE TABLE staging.st_plano_contas AS TABLE public.plano_contas;
CREATE TABLE staging.st_saldo_anterior AS TABLE public.saldo_anterior;

-- Visualizar tabelas db_cash_flow_uv, schema staging.
SELECT * FROM staging.st_bancos;
SELECT * FROM staging.st_movimentos;
SELECT * FROM staging.st_plano_contas;
SELECT * FROM staging.st_saldo_anterior;

-- Transformações

-- staging, tabela st_bancos
-- Coluna Banco_ID, alterar tipo de dado:
ALTER TABLE staging.st_bancos 
ALTER COLUMN "Banco_ID" TYPE SMALLINT;

SELECT * FROM staging.st_bancos;

-- staging, tabela st_plano_contas
-- Colunas Subgrupo_ID e Conta_ID, alterar tipo de dado:
ALTER TABLE staging.st_plano_contas
ALTER COLUMN "Subgrupo_ID" TYPE SMALLINT;

ALTER TABLE staging.st_plano_contas
ALTER COLUMN "Conta_ID" TYPE SMALLINT;

SELECT * FROM staging.st_plano_contas;

-- staging, tabela st_saldo_anterior
-- Coluna Banco_ID, alterar tipo de dado:
ALTER TABLE staging.st_saldo_anterior
ALTER COLUMN "Banco_ID" TYPE SMALLINT;

-- Coluna Valor, alterar tipo de dado:
ALTER TABLE staging.st_saldo_anterior
ALTER COLUMN "Valor" TYPE NUMERIC(15, 2);

SELECT * FROM staging.st_saldo_anterior;