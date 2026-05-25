{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_dept_region') }}
),

filtered_data AS (
    SELECT * 
    FROM raw_data
    WHERE "departmentcode" IS NOT NULL 
      AND TRIM("departmentcode") != ''
      AND "departmentname" IS NOT NULL
),

cleaned_data AS (
    SELECT
        CAST("departmentcode" AS INTEGER) AS cp,
        TRIM(
            REPLACE(
                REPLACE(
                    "departmentname",
                    '', 'è'
                ),
                '', 'ç'
            )
        ) AS departement,
        CAST("regioncode" AS INTEGER) AS region_code,
        TRIM("regionname") AS region
    FROM filtered_data
)

SELECT DISTINCT
    md5(concat(coalesce(cast(cp as text), ''), '-', coalesce(departement, ''))) AS silver_id,
    *
FROM cleaned_data