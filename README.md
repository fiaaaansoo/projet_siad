# 📊 Projet ELT - dbt (Assurance Santé)

Ce projet implémente une architecture ELT en trois couches (Bronze, Silver, Gold) pour transformer des données brutes d'assurance en un schéma en étoile décisionnel.

## 🚀 Guide de Test Complet

### 1. Préparation de l'environnement
Assurez-vous d'être dans votre environnement virtuel et à la racine du dossier `projet_elt`.
```powershell
cd projet_elt
# Installer les dépendances dbt
dbt deps
```

### 2. Exécution du Pipeline
Lancez la construction de toutes les tables (Silver, Gold, Anomalies).
```powershell
# Lancer tous les modèles
dbt run
```

### 3. Lancement des Tests de Qualité
Vérifiez que les données respectent les contraintes (unicité, non-nullité, valeurs acceptées).
```powershell
# Lancer les tests définis dans schema.yml
dbt test
```

---

## 🔍 Validation des Volumétries (SQL)

Pour vérifier que les transformations sont correctes, exécutez ces requêtes dans votre outil SQL (MySQL/PostgreSQL) et comparez les résultats avec les cibles.

### 1. Table de Faits (Grain : Contrat)
**Cible : 83 232 lignes**
```sql
SELECT count(*) as total_sinistres FROM gold.sinistre_fact;
```

### 2. Dimensions
| Table | Cible (Lignes) | Requête SQL |
| :--- | :--- | :--- |
| **Bénéficiaires** | ~48 903 | `SELECT count(*) FROM gold.beneficiaire_dim;` |
| **Contrats** | 83 232 | `SELECT count(*) FROM gold.contrat_dim;` |
| **Adresses** | 3 372 | `SELECT count(*) FROM gold.adresse_dim;` |
| **Actes** | 225 | `SELECT count(*) FROM gold.acte_dim;` |
| **Temps** | 1 465 | `SELECT count(*) FROM gold.temps_dim;` |
| **Âge** | 111 | `SELECT count(*) FROM gold.age_dim;` |

### 3. Suivi des Anomalies
Pour voir combien de lignes ont été rejetées et pourquoi :
```sql
-- Exemple pour les adhésions
SELECT raison_anomalie, count(*) 
FROM silver.anomalies_adhesion 
GROUP BY raison_anomalie;
```

---

## 🛠️ Rappel des 4 Piliers Silver
1. **Normalisation :** Harmonisation (ex: Sexe Homme/Femme).
2. **Typage :** Conversion (Dates, Float, Integer).
3. **Isolation :** Redirection des erreurs vers les tables `anomalies`.
4. **Règles métier simples :** Calculs de base (Âge, etc.).

*Note : Les noms de colonnes originaux sont conservés en Silver. Le renommage final (b_id, c_id, etc.) n'intervient qu'en couche Gold.*
