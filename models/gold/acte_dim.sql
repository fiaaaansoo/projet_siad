{{ config(materialized='table', schema='gold') }}

WITH raw_acts AS (
    SELECT DISTINCT 
        acte,
        designation_acte
    FROM {{ source('raw_bronze', 'bronze_prestations_sante') }}
    WHERE acte IS NOT NULL 
      AND acte != 'ACTE'
)

SELECT DISTINCT
    acte AS "Acte",
    INITCAP(TRIM(designation_acte)) AS designation_acte,
    acte AS categ_acte
FROM raw_acts