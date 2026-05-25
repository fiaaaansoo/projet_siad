{{ config(materialized='table') }}

WITH adhesion AS (
    SELECT DISTINCT 
        num_adhesion_normalise as c_id, 
        code_profession 
    FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

classification AS (
    SELECT code as code_prof FROM {{ source('raw_bronze', 'bronze_classification') }}
)

SELECT
    a.*,
    CASE
        WHEN a.c_id IS NULL THEN 'ID contrat manquant'
        WHEN a.code_profession IS NULL THEN 'Code profession manquant'
        WHEN c.code_prof IS NULL THEN 'Profession non trouvee dans referentiel : ' || a.code_profession
    END AS raison_anomalie
FROM adhesion a
LEFT JOIN classification c ON TRIM(a.code_profession) = TRIM(c.code_prof)
WHERE a.c_id IS NULL 
   OR a.code_profession IS NULL 
   OR c.code_prof IS NULL