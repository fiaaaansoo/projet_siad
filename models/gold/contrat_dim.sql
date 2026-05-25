{{ config(materialized='table', schema='gold') }}

WITH contrat_base AS (
    SELECT
        num_adhesion_normalise AS c_id,
        formule,
        categ_formule,
        type_beneficiaire,
        code_profession
    FROM {{ ref('silver_contrat') }}
),

classification AS (
    SELECT 
        "code" AS code_prof,
        "categorie" AS categ_profession,
        "famille_metier" AS famille_profession,
        "intitule" AS libelle_profession
    FROM {{ source('raw_bronze', 'bronze_classification') }}
)

SELECT DISTINCT
    CAST(c.c_id AS VARCHAR(100)) AS c_id,
    c.formule,
    c.categ_formule,
    c.type_beneficiaire,
    cl.categ_profession,
    cl.famille_profession,
    cl.libelle_profession
FROM contrat_base c
LEFT JOIN classification cl ON TRIM(c.code_profession) = TRIM(cl.code_prof)