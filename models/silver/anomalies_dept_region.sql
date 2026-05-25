{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_dept_region') }}
)

SELECT
    *,
    CASE
        WHEN "departmentcode" IS NULL THEN 'departmentcode manquant'
        WHEN "departmentname" IS NULL THEN 'departmentname manquant'
        WHEN TRIM("departmentcode") = '' THEN 'departmentcode vide'
    END AS raison_anomalie
FROM source
WHERE "departmentcode" IS NULL 
   OR "departmentname" IS NULL
   OR TRIM("departmentcode") = ''