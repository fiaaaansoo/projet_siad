{{ config(materialized='table') }}

WITH adhesion_source AS (
    SELECT 
        NUM_ADHESION_NORMALISE,
        FORMULE,
        TYPE_BENEFICIAIRE,
        CODE_PROFESSION
    FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

cleaned_data AS (
    SELECT
        CAST(NUM_ADHESION_NORMALISE AS VARCHAR(100)) AS NUM_ADHESION_NORMALISE,
        TRIM(REGEXP_REPLACE(FORMULE, '\s+', ' ')) AS FORMULE,
        TYPE_BENEFICIAIRE,
        CODE_PROFESSION
    FROM adhesion_source
)

SELECT DISTINCT *
FROM cleaned_data