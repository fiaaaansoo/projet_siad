{{ config(materialized='table', schema='gold') }}

SELECT DISTINCT
    CAST(num_beneficiaire AS INTEGER) AS b_id,
    sexe,
    regime_social
FROM {{ ref('silver_beneficiaire') }}
WHERE num_beneficiaire IS NOT NULL