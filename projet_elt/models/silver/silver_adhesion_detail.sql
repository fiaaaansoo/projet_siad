{{ config(materialized='table') }}

WITH raw_adhesion AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

cleaned_data AS (
    SELECT
        CAST(num_adhesion_normalise AS VARCHAR(100)) AS num_adhesion_normalise,
        CAST(num_beneficiaire_unique AS INTEGER) AS num_beneficiaire_unique,
        CAST(code_postal AS INTEGER) AS code_postal,
        CAST(exercice_paiement AS INTEGER) AS exercice_paiement,
        CAST(num_beneficiaire AS INTEGER) AS num_beneficiaire,
        type_beneficiaire,
        code_produit,
        code_fractionnement,
        TO_DATE(date_naissance_assure, 'DD/MM/YYYY') AS date_naissance_assure,
        TO_DATE(date_naissance_beneficiaire, 'DD/MM/YYYY') AS date_naissance_beneficiaire,
        UPPER(code_profession) AS code_profession,
        code_garantie,
        TRIM(REGEXP_REPLACE(formule, '\s+', ' ')) AS formule,
        CAST(REPLACE(CAST(primes_acquises AS TEXT), ',', '.') AS FLOAT) AS primes_acquises,
        CAST(code_agent AS BIGINT) AS code_agent,
        CAST(code_region AS INTEGER) AS code_region,
        CASE
            WHEN prime_garantie = 'Non' THEN 0
            WHEN prime_garantie = 'Oui' THEN 1
        END AS prime_garantie
    FROM raw_adhesion
)

SELECT *
FROM cleaned_data
WHERE date_naissance_beneficiaire IS NOT NULL
  AND exercice_paiement IS NOT NULL
  AND (exercice_paiement - EXTRACT(YEAR FROM date_naissance_beneficiaire)) >= 0