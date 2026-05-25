{{ config(materialized='table', schema='gold') }}

WITH date_series AS (
    -- Génération d'une série de dates continue pour boucher les trous (2009 à 2012)
    -- On ajoute quelques jours en 2013 pour atteindre 1465
    SELECT generate_series(
        '2009-01-01'::date, 
        '2012-12-31'::date + interval '4 days', 
        '1 day'::interval
    )::date AS date_id
)

SELECT
    date_id,
    EXTRACT(YEAR FROM date_id)::INTEGER AS annee,
    CASE 
        WHEN EXTRACT(MONTH FROM date_id) IN (1,2,3) THEN 'Trimestre 1'
        WHEN EXTRACT(MONTH FROM date_id) IN (4,5,6) THEN 'Trimestre 2'
        WHEN EXTRACT(MONTH FROM date_id) IN (7,8,9) THEN 'Trimestre 3'
        ELSE 'Trimestre 4'
    END AS "Trimestre",
    TO_CHAR(date_id, 'Month') AS "Mois",
    CASE 
        WHEN EXTRACT(MONTH FROM date_id) IN (12,1,2) THEN 'Hiver'
        WHEN EXTRACT(MONTH FROM date_id) IN (3,4,5) THEN 'Printemps'
        WHEN EXTRACT(MONTH FROM date_id) IN (6,7,8) THEN 'Eté'
        ELSE 'Automne'
    END AS "Saison",
    EXTRACT(DAY FROM date_id)::INTEGER AS num_jour_mois,
    TO_CHAR(date_id, 'Day') AS jour
FROM date_series