{{ config(materialized='table') }}

WITH adhesion_source AS (
    SELECT 
        num_adhesion_normalise,
        formule,
        type_beneficiaire,
        code_profession
    FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

cleaned_data AS (
    SELECT
        CAST(num_adhesion_normalise AS VARCHAR(100)) AS num_adhesion_normalise,
        TRIM(REGEXP_REPLACE(formule, '\s+', ' ')) AS formule,
        type_beneficiaire,
        code_profession
    FROM adhesion_source
)

SELECT DISTINCT *
FROM cleaned_data