{{ config(materialized='table', schema='gold') }}

WITH prestations_agg AS (
    -- On agrège les montants par contrat et bénéficiaire pour ne pas multiplier les lignes
    SELECT 
        num_adhesion,
        num_beneficiaire,
        MAX(acte) AS Acte,
        MAX(date_soins) AS date_soins,
        MAX(date_remboursements) AS date_remboursements,
        SUM(frais_reel) AS frais_reel,
        SUM(montant_secu) AS montant_secu,
        SUM(montant_rembourse) AS montant_rembourse
    FROM {{ ref('silver_prestations_sante') }}
    GROUP BY num_adhesion, num_beneficiaire
),

adhesions AS (
    -- La base de 83 232 lignes (Contrats)
    SELECT * FROM {{ ref('silver_adhesion_detail') }}
),

meteo AS (
    SELECT * FROM {{ ref('silver_meteo') }}
),

joined AS (
    SELECT
        a.num_beneficiaire_unique AS b_id,
        a.code_postal AS cp,
        a.age AS age_id,
        COALESCE(p.Acte, 'NC') AS Acte,
        a.num_adhesion_normalise AS c_id,
        COALESCE(p.date_soins, TO_DATE(a.exercice_paiement || '-01-01', 'YYYY-MM-DD')) AS date_soins,
        p.date_remboursements,
        
        m.temperature,
        (EXTRACT(YEAR FROM COALESCE(p.date_soins, TO_DATE(a.exercice_paiement || '-01-01', 'YYYY-MM-DD'))) - a.exercice_paiement) AS anciennete,
        
        COALESCE(p.frais_reel, 0) AS frais_reel,
        COALESCE(p.montant_secu, 0) AS montant_secu,
        COALESCE(p.montant_rembourse, 0) AS montant_rembourse
        
    FROM adhesions a
    LEFT JOIN prestations_agg p ON a.num_adhesion_normalise = p.num_adhesion 
                               AND a.num_beneficiaire = p.num_beneficiaire
    LEFT JOIN meteo m ON CAST(
                            CASE 
                                WHEN LENGTH(CAST(a.code_postal AS TEXT)) = 5 THEN 
                                    CASE 
                                        WHEN LEFT(CAST(a.code_postal AS TEXT), 3) IN ('971', '972', '973', '974', '976') THEN LEFT(CAST(a.code_postal AS TEXT), 3)
                                        ELSE LEFT(CAST(a.code_postal AS TEXT), 2)
                                    END
                                ELSE CAST(a.code_postal AS TEXT) 
                            END 
                         AS VARCHAR) = CAST(m.cp AS VARCHAR)
                      AND COALESCE(p.date_soins, TO_DATE(a.exercice_paiement || '-01-01', 'YYYY-MM-DD')) = m.date_meteo
)

SELECT
    CAST(b_id AS INTEGER) AS b_id,
    CAST(cp AS INTEGER) AS cp,
    CAST(age_id AS INTEGER) AS age_id,
    CAST(Acte AS VARCHAR(10)) AS Acte,
    CAST(c_id AS VARCHAR(100)) AS c_id,
    date_soins,
    date_remboursements,
    CAST(temperature AS FLOAT) AS temperature,
    CAST(anciennete AS INTEGER) AS anciennete,
    CAST(frais_reel AS FLOAT) AS frais_reel,
    CAST(montant_secu AS FLOAT) AS montant_secu,
    CAST(montant_rembourse AS FLOAT) AS montant_rembourse
FROM joined