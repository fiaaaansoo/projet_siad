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
        CAST("departement" AS VARCHAR) AS departement,
        TO_DATE("date", 'YYYY-MM-DD') AS date,
        CAST(REPLACE(CAST("tempmin" AS TEXT), ',', '.') AS FLOAT) AS tempmin,
        CAST(REPLACE(CAST("tempmax" AS TEXT), ',', '.') AS FLOAT) AS tempmax,
        CAST(REPLACE(CAST("ventmax" AS TEXT), ',', '.') AS FLOAT) AS ventmax,
        CAST(REPLACE(CAST("precip" AS TEXT), ',', '.') AS FLOAT) AS precip
    FROM filtered_data
)

SELECT DISTINCT *
FROM cleaned_data