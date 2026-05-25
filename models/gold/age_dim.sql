{{ config(materialized='table', schema='gold') }}

SELECT DISTINCT
    age AS age_id,
    gp_age
FROM {{ ref('silver_adhesion_detail') }}
WHERE age IS NOT NULL