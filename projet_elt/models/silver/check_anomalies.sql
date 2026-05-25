{{ config(materialized='view', schema='silver') }}

SELECT raison_anomalie, count(*) as nb_lignes
FROM {{ ref('anomalies_adhesion') }}
GROUP BY raison_anomalie
ORDER BY nb_lignes DESC
