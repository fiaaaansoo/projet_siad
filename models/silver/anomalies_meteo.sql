{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_meteo') }}
)

SELECT
    *,
    CASE
        WHEN "departement" IS NULL THEN 'departement manquant'
        WHEN "date" IS NULL THEN 'date manquante'
        WHEN "tempmin" IS NULL THEN 'tempmin manquante'
        WHEN "tempmax" IS NULL THEN 'tempmax manquante'
    END AS raison_anomalie
FROM source
WHERE "departement" IS NULL 
   OR "date" IS NULL
   OR "tempmin" IS NULL
   OR "tempmax" IS NULL