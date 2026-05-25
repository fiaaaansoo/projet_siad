{{ config(materialized='table') }}

WITH raw_adhesion AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_adhesion_detail') }}
),

clean_base AS (
    SELECT 
        *,
        TO_DATE(DATE_NAISSANCE_BENEFICIAIRE, 'DD/MM/YYYY') AS dt_naiss_ben,
        CAST(EXERCICE_PAIEMENT AS INTEGER) AS exercice_paiement_val
    FROM raw_adhesion
),

age_calculation AS (
    SELECT 
        cb.*,
        (cb.exercice_paiement_val - EXTRACT(YEAR FROM cb.dt_naiss_ben))::INTEGER AS age_val
    FROM clean_base cb
)

SELECT
    md5(concat(
        coalesce(cast(NUM_ADHESION_NORMALISE as text), ''), '-',
        coalesce(cast(NUM_BENEFICIAIRE_UNIQUE as text), ''), '-',
        coalesce(cast(EXERCICE_PAIEMENT as text), ''),
        cast(row_number() over() as text)
    )) AS silver_id,

    CAST(NUM_ADHESION_NORMALISE AS VARCHAR(100)) AS num_adhesion_normalise,
    CAST(NUM_BENEFICIAIRE_UNIQUE AS INTEGER) AS num_beneficiaire_unique,
    
    CAST(CODE_POSTAL AS INTEGER) AS code_postal,
    
    exercice_paiement_val AS exercice_paiement,
    CAST(NUM_BENEFICIAIRE AS INTEGER) AS num_beneficiaire,
    
    TYPE_BENEFICIAIRE AS type_beneficiaire,
    CASE
        WHEN TYPE_BENEFICIAIRE = 'AS' THEN 'Assuré principal'
        WHEN TYPE_BENEFICIAIRE = 'EN' THEN 'Enfant'
        WHEN TYPE_BENEFICIAIRE = 'CO' THEN 'Conjoint'
    END AS type_beneficiaire_libelle,

    CODE_PRODUIT AS code_produit,
    CASE
        WHEN CODE_PRODUIT = 'C' THEN 'Collectif'
        WHEN CODE_PRODUIT = 'M' THEN 'Individuel'
    END AS code_produit_libelle,

    CODE_FRACTIONNEMENT AS code_fractionnement,
    CASE
        WHEN CODE_FRACTIONNEMENT = 'A' THEN 'Annuel'
        WHEN CODE_FRACTIONNEMENT = 'S' THEN 'Semestriel'
        WHEN CODE_FRACTIONNEMENT = 'T' THEN 'Trimestriel'
        WHEN CODE_FRACTIONNEMENT = 'M' THEN 'Mensuel'
        WHEN CODE_FRACTIONNEMENT = 'P' THEN 'Unique'
    END AS code_fractionnement_libelle,

    TO_DATE(DATE_NAISSANCE_ASSURE, 'DD/MM/YYYY') AS date_naissance_assure,
    dt_naiss_ben AS date_naissance_beneficiaire,
    
    UPPER(CODE_PROFESSION) AS code_profession,
    CODE_GARANTIE AS code_garantie,
    
    TRIM(REGEXP_REPLACE(FORMULE, '\s+', ' ')) AS formule,
    SPLIT_PART(TRIM(REGEXP_REPLACE(FORMULE, '\s+', ' ')), ' ', 1) AS categ_formule,
    
    CAST(REPLACE(CAST(PRIMES_ACQUISES AS TEXT), ',', '.') AS FLOAT) AS primes_acquises,
    CAST(CODE_AGENT AS BIGINT) AS code_agent,
    CAST(CODE_REGION AS INTEGER) AS code_region,
    
    CASE 
        WHEN PRIME_GARANTIE = 'Non' THEN 0 
        WHEN PRIME_GARANTIE = 'Oui' THEN 1 
    END AS is_prime_garantie,
    
    age_val AS age,
    CASE
        WHEN age_val BETWEEN 0 AND 2 THEN 'Nourrisson'
        WHEN age_val BETWEEN 3 AND 11 THEN 'Enfant'
        WHEN age_val BETWEEN 12 AND 14 THEN 'Pré-adolescent'
        WHEN age_val BETWEEN 15 AND 17 THEN 'Adolescent'
        WHEN age_val BETWEEN 18 AND 25 THEN 'Jeune adulte'
        WHEN age_val BETWEEN 26 AND 59 THEN 'Adulte'
        WHEN age_val >= 60 THEN 'Senior'
    END AS gp_age

FROM age_calculation
WHERE date_naissance_beneficiaire IS NOT NULL
  AND exercice_paiement IS NOT NULL
  AND age_val IS NOT NULL
  AND age_val >= 0