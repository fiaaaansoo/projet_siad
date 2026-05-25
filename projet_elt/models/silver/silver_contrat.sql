{{ config(materialized='table') }}

WITH adhesion_source AS (
    SELECT 
        NUM_ADHESION_NORMALISE AS num_adhesion_raw,
        FORMULE,
        TYPE_BENEFICIAIRE,
        CODE_PROFESSION
    FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

cleaned_data AS (
    SELECT
        CAST(num_adhesion_raw AS VARCHAR(100)) AS num_adhesion_normalise,
        TRIM(REGEXP_REPLACE(FORMULE, '\s+', ' ')) AS formule,
        SPLIT_PART(TRIM(REGEXP_REPLACE(FORMULE, '\s+', ' ')), ' ', 1) AS categ_formule,
        TYPE_BENEFICIAIRE AS type_beneficiaire,
        CODE_PROFESSION AS code_profession
    FROM adhesion_source
)

SELECT
    md5(concat(
        coalesce(cast(num_adhesion_normalise as text), ''), '-', 
        coalesce(type_beneficiaire, ''), '-',
        coalesce(formule, ''),
        cast(row_number() over() as text)
    )) AS silver_id,
    *
FROM cleaned_data