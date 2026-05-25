{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_meteo') }}
),

filtered_data AS (
    SELECT * 
    FROM raw_data
    WHERE "departement" IS NOT NULL 
      AND "date" IS NOT NULL
      AND "tempmin" IS NOT NULL
      AND "tempmax" IS NOT NULL
),

cleaned_data AS (
    SELECT
        CAST("departement" AS VARCHAR) AS cp,
        TO_DATE("date", 'YYYY-MM-DD') AS date_meteo,
        (
            CAST(REPLACE(CAST("tempmin" AS TEXT), ',', '.') AS FLOAT) + 
            CAST(REPLACE(CAST("tempmax" AS TEXT), ',', '.') AS FLOAT)
        ) / 2 AS temperature,
        CAST(REPLACE(CAST("ventmax" AS TEXT), ',', '.') AS FLOAT) AS vent_max,
        CAST(REPLACE(CAST("precip" AS TEXT), ',', '.') AS FLOAT) AS precipitations
    FROM filtered_data
)

SELECT DISTINCT
    md5(concat(cast(cp as text), '-', cast(date_meteo as text))) AS silver_id,
    *
FROM cleaned_data