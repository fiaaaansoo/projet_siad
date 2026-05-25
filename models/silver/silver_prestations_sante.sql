{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_prestations_sante') }}
    WHERE num_sinistre IS NOT NULL 
      AND num_sinistre NOT IN ('', 'NUM_SINISTRE')
      AND frais_reel_assure IS NOT NULL
),

transformations AS (
    SELECT
        TO_DATE(LPAD(jour_debut_soins, 2, '0') || '/' || LPAD(mois_debut_soins, 2, '0') || '/' || annee_debut_soins, 'DD/MM/YYYY') AS date_soins,
        TO_DATE(LPAD(jour_paiement, 2, '0') || '/' || LPAD(mois_paiement, 2, '0') || '/' || annee_paiement, 'DD/MM/YYYY') AS date_remboursements,
        
        CAST(jour_debut_soins AS INTEGER) AS jour_debut_soins,
        CAST(mois_debut_soins AS INTEGER) AS mois_debut_soins,
        CAST(annee_debut_soins AS INTEGER) AS annee_debut_soins,
        CAST(jour_paiement AS INTEGER) AS jour_paiement,
        CAST(mois_paiement AS INTEGER) AS mois_paiement,
        CAST(annee_paiement AS INTEGER) AS annee_paiement,
        
        CAST(REPLACE(frais_reel_assure, ',', '.') AS FLOAT) AS frais_reel,
        CAST(REPLACE(montant_secu, ',', '.') AS FLOAT) AS montant_secu,
        CAST(REPLACE(montant_rembourse, ',', '.') AS FLOAT) AS montant_rembourse,
        
        TRIM(acte) AS acte,
        INITCAP(TRIM(designation_acte)) AS designation_acte,
        UPPER(TRIM(libelle_bareme)) AS libelle_bareme,
        
        CAST(num_sinistre AS BIGINT) AS num_sinistre,
        CAST(num_adhesion AS VARCHAR(100)) AS num_adhesion,
        CAST(num_beneficiaire AS INTEGER) AS num_beneficiaire,
        CAST(num_beneficiaire_sinistre AS INTEGER) AS num_beneficiaire_sinistre
    FROM raw_data
    WHERE num_beneficiaire IS NOT NULL
      AND num_adhesion IS NOT NULL
),

final_filter AS (
    SELECT * FROM transformations
    WHERE frais_reel >= 0
      AND montant_secu >= 0
      AND montant_rembourse >= 0
      AND (montant_rembourse + montant_secu) <= (frais_reel + 0.01)
      AND date_remboursements >= date_soins
)

SELECT DISTINCT
    md5(concat(
        cast(num_sinistre as text), '-', 
        cast(num_adhesion as text), '-', 
        cast(date_soins as text), '-',
        cast(montant_rembourse as text)
    )) AS silver_id,
    *
FROM final_filter