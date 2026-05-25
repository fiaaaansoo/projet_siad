{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

beneficiaire AS (
    SELECT 
        CAST(num_beneficiaire AS INTEGER) AS num_ben_id,
        TRIM(sexe) AS sexe
    FROM {{ source('raw_bronze', 'bronze_beneficiaire') }}
),

joined AS (
    SELECT 
        s.*,
        b.sexe
    FROM source s
    LEFT JOIN beneficiaire b ON CAST(s.num_beneficiaire_unique AS INTEGER) = b.num_ben_id
)

SELECT
    *,
    CASE
        WHEN num_adhesion_normalise IS NULL
            THEN 'num_adhesion_normalise manquant'
        WHEN date_naissance_beneficiaire IS NULL
            THEN 'date_naissance_beneficiaire manquante'
        WHEN exercice_paiement IS NULL
            THEN 'exercice_paiement manquant'
        WHEN type_beneficiaire NOT IN ('AS', 'EN', 'CO')
            THEN 'type_beneficiaire invalide : ' || type_beneficiaire
        WHEN code_postal = '0'
            THEN 'code_postal invalide (valeur 0)'
        WHEN CAST(primes_acquises AS DECIMAL(10,2)) < 0
            THEN 'prime negative : ' || primes_acquises
        WHEN (
            CAST(exercice_paiement AS INTEGER)
            - EXTRACT(YEAR FROM TO_DATE(date_naissance_beneficiaire, 'DD/MM/YYYY'))::INTEGER
        ) < 0
            THEN 'age negatif : ' || (
                CAST(exercice_paiement AS INTEGER)
                - EXTRACT(YEAR FROM TO_DATE(date_naissance_beneficiaire, 'DD/MM/YYYY'))::INTEGER
            )::TEXT
        WHEN sexe IS NULL OR sexe = ''
            THEN 'sexe manquant'
        WHEN sexe NOT IN ('M', 'F')
            THEN 'sexe invalide : ' || sexe
    END AS raison_anomalie
FROM joined
WHERE num_adhesion_normalise IS NULL
   OR date_naissance_beneficiaire IS NULL
   OR exercice_paiement IS NULL
   OR type_beneficiaire NOT IN ('AS', 'EN', 'CO')
   OR code_postal = '0'
   OR CAST(primes_acquises AS DECIMAL(10,2)) < 0
   OR (
        CAST(exercice_paiement AS INTEGER)
        - EXTRACT(YEAR FROM TO_DATE(date_naissance_beneficiaire, 'DD/MM/YYYY'))::INTEGER
    ) < 0
   OR sexe IS NULL 
   OR sexe NOT IN ('M', 'F')