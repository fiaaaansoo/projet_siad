{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

beneficiaire AS (
    SELECT 
        CAST(NUM_BENEFICIAIRE AS INTEGER) AS num_ben_id,
        TRIM(SEXE) AS sexe
    FROM {{ source('raw_bronze', 'bronze_beneficiaire') }}
),

joined AS (
    SELECT 
        s.*,
        b.sexe
    FROM source s
    LEFT JOIN beneficiaire b ON CAST(s.NUM_BENEFICIAIRE_UNIQUE AS INTEGER) = b.num_ben_id
)

SELECT
    *,
    CASE
        WHEN NUM_ADHESION_NORMALISE IS NULL
            THEN 'num_adhesion_normalise manquant'
        WHEN DATE_NAISSANCE_BENEFICIAIRE IS NULL
            THEN 'date_naissance_beneficiaire manquante'
        WHEN EXERCICE_PAIEMENT IS NULL
            THEN 'exercice_paiement manquant'
        WHEN TYPE_BENEFICIAIRE NOT IN ('AS', 'EN', 'CO')
            THEN 'type_beneficiaire invalide : ' || TYPE_BENEFICIAIRE
        WHEN CODE_POSTAL = '0'
            THEN 'code_postal invalide (valeur 0)'
        WHEN CAST(PRIMES_ACQUISES AS DECIMAL(10,2)) < 0
            THEN 'prime negative : ' || PRIMES_ACQUISES
        WHEN (
            CAST(EXERCICE_PAIEMENT AS INTEGER)
            - EXTRACT(YEAR FROM TO_DATE(DATE_NAISSANCE_BENEFICIAIRE, 'DD/MM/YYYY'))::INTEGER
        ) < 0
            THEN 'age negatif : ' || (
                CAST(EXERCICE_PAIEMENT AS INTEGER)
                - EXTRACT(YEAR FROM TO_DATE(DATE_NAISSANCE_BENEFICIAIRE, 'DD/MM/YYYY'))::INTEGER
            )::TEXT
        WHEN sexe IS NULL OR sexe = ''
            THEN 'sexe manquant'
        WHEN sexe NOT IN ('M', 'F')
            THEN 'sexe invalide : ' || sexe
    END AS raison_anomalie
FROM joined
WHERE NUM_ADHESION_NORMALISE IS NULL
   OR DATE_NAISSANCE_BENEFICIAIRE IS NULL
   OR EXERCICE_PAIEMENT IS NULL
   OR TYPE_BENEFICIAIRE NOT IN ('AS', 'EN', 'CO')
   OR CODE_POSTAL = '0'
   OR CAST(PRIMES_ACQUISES AS DECIMAL(10,2)) < 0
   OR (
        CAST(EXERCICE_PAIEMENT AS INTEGER)
        - EXTRACT(YEAR FROM TO_DATE(DATE_NAISSANCE_BENEFICIAIRE, 'DD/MM/YYYY'))::INTEGER
    ) < 0
   OR sexe IS NULL 
   OR sexe NOT IN ('M', 'F')