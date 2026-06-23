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

/* 
Obs.:
Foram inseridos novos dados no dataset Movimentos.xlsx.
Staging: Para a tabela st_movimentos, limpar e repopular. 
É preciso realizar os UPDATES necessários na tabela staging.st_movimentos (ALTER TABLE).
*/

TRUNCATE TABLE staging.st_movimentos;
INSERT INTO staging.st_movimentos SELECT * FROM public.movimentos;

SELECT * FROM staging.st_movimentos;

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

/* 
Consulta acima poderia ser agrupada:
ALTER TABLE staging.st_plano_contas
    ALTER COLUMN "Subgrupo_ID" TYPE SMALLINT,
    ALTER COLUMN "Conta_ID"    TYPE SMALLINT;
*/	

-- staging, tabela st_saldo_anterior
-- Coluna Banco_ID, alterar tipo de dado:
ALTER TABLE staging.st_saldo_anterior
ALTER COLUMN "Banco_ID" TYPE SMALLINT;

-- Coluna Valor, alterar tipo de dado:
ALTER TABLE staging.st_saldo_anterior
ALTER COLUMN "Valor" TYPE NUMERIC(15, 2);

/*
Consulta acima poderia ser agrupada:
ALTER TABLE staging.st_saldo_anterior
    ALTER COLUMN "Banco_ID" TYPE SMALLINT,
    ALTER COLUMN "Valor"    TYPE NUMERIC(15, 2);
*/

-- Inserir coluna Saldo_ID
ALTER TABLE staging.st_saldo_anterior
ADD COLUMN "Saldo_ID" SMALLINT GENERATED ALWAYS AS IDENTITY;

SELECT * FROM staging.st_saldo_anterior;

-- staging, tabela st_movimentos
-- Coluna Tipo:
UPDATE staging.st_movimentos
SET "Tipo" = 'E'
WHERE "Tipo" = 'Entradas';

UPDATE staging.st_movimentos
SET "Tipo" = 'S'
WHERE "Tipo" = 'Saídas';

SELECT * FROM staging.st_movimentos;

-- Coluna Data:
ALTER TABLE staging.st_movimentos
ALTER COLUMN "Data" TYPE Date
USING "Data"::date;

SELECT * FROM staging.st_movimentos;

-- Coluna Valor:
ALTER TABLE staging.st_movimentos
ALTER COLUMN "Valor" TYPE NUMERIC(15, 2);

SELECT * FROM staging.st_movimentos;

-- Inserindo colunas Banco_ID e Conta_ID. 
-- Excluindo colunas Banco e Conta.
CREATE TABLE staging.st_movimentos_new AS
SELECT
	b."Banco_ID",
	c."Conta_ID",
	m."Tipo",
	m."Data",
	m."Valor"
FROM staging.st_movimentos m
LEFT JOIN staging.st_bancos b ON m."Banco" = b."Banco"
LEFT JOIN staging.st_plano_contas c ON m."Conta" = c."Conta";

SELECT * FROM staging.st_movimentos_new;

/* 
Obs.:
Foram inseridos novos dados no dataset Movimentos.xlsx.
Staging: Para a tabela st_movimentos_new, limpar e repopular. 
*/

TRUNCATE TABLE staging.st_movimentos_new;

INSERT INTO staging.st_movimentos_new
SELECT
	b."Banco_ID",
	c."Conta_ID",
	m."Tipo",
	m."Data",
	m."Valor"
FROM staging.st_movimentos m
LEFT JOIN staging.st_bancos b ON m."Banco" = b."Banco"
LEFT JOIN staging.st_plano_contas c ON m."Conta" = c."Conta";

SELECT * FROM staging.st_movimentos_new;

-- Resumo tabelas tratadas, staging:
SELECT * FROM staging.st_bancos;
SELECT * FROM staging.st_plano_contas;
SELECT * FROM staging.st_saldo_anterior;
SELECT * FROM staging.st_movimentos_new;

-- DW (Data Warehouse)
-- Tabelas dimensão x fato a serem criadas:
-- dim_bancos, dim_plano_contas, dim_calendario, f_movimentos_new, f_saldo_anterior

-- Criar tabela dimensão dim_bancos.
CREATE TABLE dw.dim_bancos AS TABLE staging.st_bancos;

-- Definir coluna Banco_ID como primary key.
ALTER TABLE dw.dim_bancos
ADD CONSTRAINT pk_dim_bancos PRIMARY KEY ("Banco_ID");

SELECT * FROM dw.dim_bancos;

-- Criar tabela dimensão dim_plano_contas.
CREATE TABLE dw.dim_plano_contas AS TABLE staging.st_plano_contas;

-- Definir coluna Conta_ID como primary key.
ALTER TABLE dw.dim_plano_contas
ADD CONSTRAINT pk_dim_plano_contas PRIMARY KEY ("Conta_ID");

SELECT * FROM dw.dim_plano_contas;

-- Criar tabela fato ft_saldo_anterior.
CREATE TABLE dw.ft_saldo_anterior AS TABLE staging.st_saldo_anterior;

-- Definir coluna Saldo_ID como primary key (PK) & Banco_ID como foreign key (FK).
ALTER TABLE dw.ft_saldo_anterior
ADD CONSTRAINT pk_ft_saldo_anterior PRIMARY KEY ("Saldo_ID");

ALTER TABLE dw.ft_saldo_anterior
ADD CONSTRAINT fk_ft_saldo_anterior_dim_bancos
FOREIGN KEY ("Banco_ID") REFERENCES dw.dim_bancos ("Banco_ID");

SELECT * FROM dw.ft_saldo_anterior;

-- Query para verificar as chaves PK e FK da tabela dw.ft_saldo_anterior:
SELECT
    constraint_name,
    column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'dw'
AND table_name = 'ft_saldo_anterior';

-- Criar tabela dim_calendario.
CREATE TABLE dw.dim_calendario (
    -- PK
    data_id             INTEGER      NOT NULL PRIMARY KEY,

    -- Data real
    data                DATE         NOT NULL,

    -- Componentes básicos
    nr_ano              SMALLINT     NOT NULL,
    nr_mes              SMALLINT     NOT NULL,  -- 1-12
    nr_dia              SMALLINT     NOT NULL,  -- 1-31
    nr_trimestre        SMALLINT     NOT NULL,  -- 1-4
    nr_semana_ano       SMALLINT     NOT NULL,  -- ISO 8601: 1-53
    nr_dia_semana       SMALLINT     NOT NULL,  -- ISO: seg=1 ... dom=7
    nr_dia_ano          SMALLINT     NOT NULL,  -- 1-366

    -- Nomes por extenso (pt-BR)
    nm_dia_semana       VARCHAR(15)  NOT NULL,  -- 'Segunda-feira' ...
    nm_dia_semana_abrev VARCHAR(5)   NOT NULL,  -- 'Seg' ...
    nm_mes              VARCHAR(15)  NOT NULL,  -- 'Janeiro' ...
    nm_mes_abrev        VARCHAR(5)   NOT NULL,  -- 'Jan' ...

    -- Chaves "inteligentes" para agrupamentos rápidos
    nr_ano_mes          INTEGER      NOT NULL  -- AAAAMM
);

-- Popular tabela dw.dim_calendario
INSERT INTO dw.dim_calendario (
    data_id,
    data,
    nr_ano,
    nr_mes,
    nr_dia,
    nr_trimestre,
    nr_semana_ano,
    nr_dia_semana,
    nr_dia_ano,
    nm_dia_semana,
    nm_dia_semana_abrev,
    nm_mes,
    nm_mes_abrev,
    nr_ano_mes
)
SELECT
    TO_CHAR(dt, 'YYYYMMDD')::INTEGER AS data_id,
    dt AS data,

    EXTRACT(YEAR FROM dt)::SMALLINT AS nr_ano,
    EXTRACT(MONTH FROM dt)::SMALLINT AS nr_mes,
    EXTRACT(DAY FROM dt)::SMALLINT AS nr_dia,
    EXTRACT(QUARTER FROM dt)::SMALLINT AS nr_trimestre,

    EXTRACT(WEEK FROM dt)::SMALLINT AS nr_semana_ano,

    EXTRACT(ISODOW FROM dt)::SMALLINT AS nr_dia_semana,

    EXTRACT(DOY FROM dt)::SMALLINT AS nr_dia_ano,

    CASE EXTRACT(ISODOW FROM dt)
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS nm_dia_semana,

    CASE EXTRACT(ISODOW FROM dt)
        WHEN 1 THEN 'Seg'
        WHEN 2 THEN 'Ter'
        WHEN 3 THEN 'Qua'
        WHEN 4 THEN 'Qui'
        WHEN 5 THEN 'Sex'
        WHEN 6 THEN 'Sáb'
        WHEN 7 THEN 'Dom'
    END AS nm_dia_semana_abrev,

    CASE EXTRACT(MONTH FROM dt)
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END AS nm_mes,

    CASE EXTRACT(MONTH FROM dt)
        WHEN 1 THEN 'Jan'
        WHEN 2 THEN 'Fev'
        WHEN 3 THEN 'Mar'
        WHEN 4 THEN 'Abr'
        WHEN 5 THEN 'Mai'
        WHEN 6 THEN 'Jun'
        WHEN 7 THEN 'Jul'
        WHEN 8 THEN 'Ago'
        WHEN 9 THEN 'Set'
        WHEN 10 THEN 'Out'
        WHEN 11 THEN 'Nov'
        WHEN 12 THEN 'Dez'
    END AS nm_mes_abrev,

    TO_CHAR(dt, 'YYYYMM')::INTEGER AS nr_ano_mes

FROM generate_series(
        DATE '2023-01-01',
        DATE '2024-05-31',
        INTERVAL '1 day'
     ) AS g(dt);

SELECT * FROM dw.dim_calendario;

-- Criar tabela fato ft_movimentos.
CREATE TABLE dw.ft_movimentos AS TABLE staging.st_movimentos_new;

/* 
Obs.:
Foram inseridos novos dados no dataset Movimentos.xlsx.
dw: Para a tabela dw_ft_movimentos, limpar e repopular. 
*/

TRUNCATE TABLE dw.ft_movimentos;

INSERT INTO dw.ft_movimentos
SELECT * FROM staging.st_movimentos_new;

SELECT * FROM dw.vw_ft_movimentos;

-- Resumo tabelas dw:
SELECT * FROM dw.dim_bancos;
SELECT * FROM dw.dim_plano_contas;
SELECT * FROM dw.dim_calendario;
SELECT * FROM dw.ft_saldo_anterior;
SELECT * FROM dw.ft_movimentos;

-- Views para conectar com power bi:

-- vw_dim_bancos
CREATE OR REPLACE VIEW dw.vw_dim_bancos AS
SELECT
  "Banco_ID",
  "Banco"
from dw.dim_bancos;

SELECT * FROM dw.vw_dim_bancos;

-- vw_dim_plano_contas
CREATE OR REPLACE VIEW dw.vw_dim_plano_contas AS
SELECT
  "Conta_ID",
  "Conta",
  "Subgrupo_ID",
  "Subgrupo"
from dw.dim_plano_contas;

SELECT * FROM dw.vw_dim_plano_contas;

-- vw_dim_calendario
CREATE OR REPLACE VIEW dw.vw_dim_calendario AS
SELECT
  	data_id,
    data,
    nr_ano,
    nr_mes,
    nr_dia,
    nr_trimestre,
    nr_semana_ano,
    nr_dia_semana,
    nr_dia_ano,
    nm_dia_semana,
    nm_dia_semana_abrev,
    nm_mes,
    nm_mes_abrev,
    nr_ano_mes
FROM dw.dim_calendario;

SELECT * FROM dw.vw_dim_calendario;

-- vw_fato_saldo_anterior
CREATE OR REPLACE VIEW dw.vw_ft_saldo_anterior AS
SELECT
  "Saldo_ID",
  "Banco_ID",
  "Valor"
FROM dw.ft_saldo_anterior;

SELECT * FROM dw.vw_ft_saldo_anterior;

-- vw_ft_movimentos
CREATE OR REPLACE VIEW dw.vw_ft_movimentos AS
select
  "Banco_ID",  
  "Conta_ID",   
  "Tipo",
  "Data",
  "Valor"
FROM dw.ft_movimentos;

SELECT * FROM dw.vw_ft_movimentos;

-- Resumo views criadas:
SELECT * FROM dw.vw_dim_bancos;
SELECT * FROM dw.vw_dim_plano_contas;
SELECT * FROM dw.vw_dim_calendario;
SELECT * FROM dw.vw_ft_saldo_anterior;
SELECT * FROM dw.vw_ft_movimentos;

SELECT * FROM staging.st_movimentos
WHERE "Data" IS NULL OR "Valor" = 0 OR "Valor" IS NULL;

SELECT * FROM public.movimentos
WHERE "Data" IS NULL OR "Valor" = 0 OR "Valor" IS NULL;