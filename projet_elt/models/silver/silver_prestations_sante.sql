{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT * FROM {{ source('raw_bronze', 'bronze_prestations_sante') }}
    WHERE num_sinistre IS NOT NULL 
      AND num_sinistre NOT IN ('', 'NUM_SINISTRE')
      AND frais_reel_assure IS NOT NULL
),

cleaned_data AS (
    SELECT
        CAST(num_sinistre AS BIGINT) AS num_sinistre,
        CAST(num_adhesion AS VARCHAR(100)) AS num_adhesion,
        CAST(num_beneficiaire AS INTEGER) AS num_beneficiaire,
        CAST(num_beneficiaire_sinistre AS INTEGER) AS num_beneficiaire_sinistre,
        CAST(jour_debut_soins AS INTEGER) AS jour_debut_soins,
        CAST(mois_debut_soins AS INTEGER) AS mois_debut_soins,
        CAST(annee_debut_soins AS INTEGER) AS annee_debut_soins,
        CAST(jour_paiement AS INTEGER) AS jour_paiement,
        CAST(mois_paiement AS INTEGER) AS mois_paiement,
        CAST(annee_paiement AS INTEGER) AS annee_paiement,
        CAST(REPLACE(frais_reel_assure, ',', '.') AS FLOAT) AS frais_reel_assure,
        CAST(REPLACE(montant_secu, ',', '.') AS FLOAT) AS montant_secu,
        CAST(REPLACE(montant_rembourse, ',', '.') AS FLOAT) AS montant_rembourse,
        TRIM(acte) AS acte,
        INITCAP(TRIM(designation_acte)) AS designation_acte,
        UPPER(TRIM(libelle_bareme)) AS libelle_bareme
    FROM raw_data
    WHERE num_beneficiaire IS NOT NULL
      AND num_adhesion IS NOT NULL
),

final_filter AS (
    SELECT * FROM cleaned_data
    WHERE frais_reel_assure >= 0
      AND montant_secu >= 0
      AND montant_rembourse >= 0
      AND (montant_rembourse + montant_secu) <= (frais_reel_assure + 0.01)
      -- On laisse la validation de date chronologique pour la Gold car on n'a pas encore fusionné les colonnes ici
)

SELECT * FROM final_filter