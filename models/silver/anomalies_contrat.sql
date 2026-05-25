{{ config(materialized='table') }}

WITH adhesion AS (
    SELECT DISTINCT 
        NUM_ADHESION_NORMALISE as c_id, 
        CODE_PROFESSION 
    FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

classification AS (
    SELECT code as code_prof FROM {{ source('raw_bronze', 'bronze_classification') }}
)

SELECT
    a.*,
    CASE
        WHEN a.c_id IS NULL THEN 'ID contrat manquant'
        WHEN a.CODE_PROFESSION IS NULL THEN 'Code profession manquant'
        WHEN c.code_prof IS NULL THEN 'Profession non trouvee dans referentiel : ' || a.CODE_PROFESSION
    END AS raison_anomalie
FROM adhesion a
LEFT JOIN classification c ON TRIM(a.CODE_PROFESSION) = TRIM(c.code_prof)
WHERE a.c_id IS NULL 
   OR a.CODE_PROFESSION IS NULL 
   OR c.code_prof IS NULL