{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_beneficiaire') }}
),

cleaned_data AS (
    SELECT
        CAST(num_beneficiaire AS INTEGER) AS num_beneficiaire,
        CASE 
            WHEN TRIM(sexe) = 'M' THEN 'Homme'
            WHEN TRIM(sexe) = 'F' THEN 'Femme'
            ELSE TRIM(sexe)
        END AS sexe,
        TRIM(regime_social) AS regime_social
    FROM raw_data
    WHERE num_beneficiaire IS NOT NULL
      AND sexe IS NOT NULL
      AND regime_social IS NOT NULL
)

SELECT DISTINCT *
FROM cleaned_data