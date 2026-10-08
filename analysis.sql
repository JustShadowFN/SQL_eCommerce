-- ============================================================
-- analysis.sql
-- Toutes les requêtes d'analyse de la plateforme e-commerce
--
-- Noms de tables et colonnes alignés sur seed_ecommerce.sql :
--   client(id, nom, prenom, email, ville, date_inscription)
--   produit(id, nom, categorie, prix, stock)
--   commande(id, client_id, date_commande, statut)
--   ligne_commande(id, commande_id, produit_id, quantite, prix_unitaire)
--
-- Règle de calcul :
--   montant d'une ligne = quantite * prix_unitaire (prix effectivement payé)
--   Les commandes au statut 'annulée' sont exclues du chiffre d'affaires,
--   des quantités vendues et du panier moyen (à appliquer dans les
--   requêtes d'agrégation suivantes : WHERE c.statut <> 'annulée').
-- ============================================================

SET client_encoding = 'UTF8';


-- ============================================================
-- Exercice 1 — Explorer les produits
-- ============================================================

-- 1.a Liste des produits : nom, catégorie, prix, stock
SELECT nom, categorie, prix, stock
FROM produit
ORDER BY categorie, nom;

-- 1.b Produits dont le prix est supérieur à 100 €
SELECT nom, categorie, prix, stock
FROM produit
WHERE prix > 100
ORDER BY prix DESC;


-- ============================================================
-- Exercice 2 — Explorer les clients
-- ============================================================

-- 2.a Clients habitant dans une ville donnée (exemple : Paris)
SELECT id, nom, prenom, email, ville, date_inscription
FROM client
WHERE ville = 'Paris'
ORDER BY nom, prenom;

-- 2.b Nombre de clients enregistrés dans chaque ville
SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC, ville;


-- ============================================================
-- Exercice 3 — Explorer les commandes
-- ============================================================

-- Commandes avec identifiant, date, statut et informations du client
SELECT
    c.id            AS commande_id,
    c.date_commande,
    c.statut,
    cl.id           AS client_id,
    cl.nom,
    cl.prenom,
    cl.email,
    cl.ville
FROM commande c
JOIN client cl ON cl.id = c.client_id
ORDER BY c.date_commande, c.id;


-- ============================================================
-- Exercice 4 — Calculer le montant d'une ligne
-- ============================================================

-- Montant de chaque ligne = quantité * prix effectivement payé
SELECT
    lc.id            AS ligne_id,
    lc.commande_id,
    lc.produit_id,
    lc.quantite,
    lc.prix_unitaire,
    lc.quantite * lc.prix_unitaire AS montant_ligne
FROM ligne_commande lc
ORDER BY lc.commande_id, lc.id;


-- ============================================================
-- Exercice 5 — Calculer le montant des commandes
-- ============================================================

-- Montant total de chaque commande (toutes les commandes affichées,
-- le statut permet de repérer les commandes annulées).
-- LEFT JOIN + COALESCE : une commande sans ligne affiche 0.
SELECT
    c.id            AS commande_id,
    c.date_commande,
    c.statut,
    COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
FROM commande c
LEFT JOIN ligne_commande lc ON lc.commande_id = c.id
GROUP BY c.id, c.date_commande, c.statut
ORDER BY c.date_commande, c.id;


-- Exercice 6: Chiffre d'affaires par catégorie

SELECT 
    p.categorie,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires,
    SUM(lc.quantite) AS quantite_totale
FROM ligne_commande lc
INNER JOIN produit p 
    ON lc.produit_id = p.id
GROUP BY p.categorie;

-- Exercice 7: Produits les plus vendus 
SELECT 
    p.nom AS produit,
    p.categorie,
    SUM(lc.quantite) AS quantite_totale_vendue
FROM ligne_commande lc
INNER JOIN produit p
    ON lc.produit_id = p.id
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_totale_vendue DESC
LIMIT 10;

-- Exercice 8: Produits générant le plus de chiffre d'affaires 
SELECT 
    p.nom AS produit,
    p.categorie,
    SUM(lc.quantite) AS quantite_totale_vendue
FROM ligne_commande lc
INNER JOIN produit p
    ON lc.produit_id = p.id
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_totale_vendue DESC
LIMIT 10;

-- Exercice 9: Clients
SELECT
    c.nom,
    c.prenom,
    COUNT(DISTINCT co.id) AS nombre_commandes,
    COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total_depense
FROM client c
LEFT JOIN commande co
    ON c.id = co.client_id
LEFT JOIN ligne_commande lc
    ON co.id = lc.commande_id
GROUP BY c.id, c.nom, c.prenom
ORDER BY montant_total_depense DESC;

-- Exercice 10: Panier moyen
-- Panier moyen global:
SELECT
    SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT co.id) AS panier_moyen
FROM commande co
INNER JOIN ligne_commande lc
    ON co.id = lc.commande_id;

-- Panier moyen par mois:
SELECT
    DATE_TRUNC('month', co.date_commande) AS mois,
    SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT co.id) AS panier_moyen
FROM commande co
INNER JOIN ligne_commande lc
    ON co.id = lc.commande_id
GROUP BY DATE_TRUNC('month', co.date_commande)
ORDER BY mois;


-- PARTIE 4

-- ============================================================
-- Exercice 11 — Explorer les produits
-- ============================================================
SELECT
  c.id AS commande_id,
  SUM(lc.quantite * lc.prix_unitaire) AS montant_total,
  CASE
    WHEN SUM(lc.quantite * lc.prix_unitaire) < 500  THEN 'Petit panier'
    WHEN SUM(lc.quantite * lc.prix_unitaire) < 1500 THEN 'Panier moyen'
    ELSE 'Gros panier'
  END AS categorie_commande
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY c.id
ORDER BY c.id;


-- ============================================================
-- Exercice 12 — Explorer les produits
-- ============================================================

-- évolution mensuelle de l'activité trié par CA
SELECT
  EXTRACT(MONTH FROM c.date_commande) AS mois,
  COUNT(DISTINCT c.id)                AS nb_commandes,
  SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY mois
ORDER BY chiffre_affaires;

-- PARTIE 5

-- ============================================================
-- Exercice 13 — Détecter une incohérence
-- ============================================================

-- 1. Affichage des anomalies (commandes antérieures à l'inscription)
SELECT 
    commande.id AS commande_id,
    commande.client_id,
    commande.date_commande,
    client.date_inscription
FROM commande
INNER JOIN client ON client.id = commande.client_id
WHERE commande.date_commande < client.date_inscription;

-- 2. Nombre total d'anomalies détectées
SELECT 
    COUNT(*) AS nombre_anomalies
FROM commande
INNER JOIN client ON client.id = commande.client_id
WHERE commande.date_commande < client.date_inscription;


-- ============================================================
-- Exercice 14 — Produits sans vente
-- ============================================================

-- 1. Requête pour identifier les produits jamais vendus
SELECT 
    produit.nom AS produit,
    produit.categorie,
    produit.prix,
    produit.stock
FROM produit
LEFT JOIN ligne_commande ON produit.id = ligne_commande.produit_id
WHERE ligne_commande.produit_id IS NULL;



-- ============================================================
-- PARTIE 6 — Tableau de bord en SQL
-- Exercice 15 — Indicateurs clés
-- ============================================================
-- Rappel de la règle de calcul (énoncé) :
--   montant d'une ligne = quantite * prix_unitaire (prix réellement payé)
--   Les commandes 'annulée' sont exclues du chiffre d'affaires (CA),
--   des quantités vendues et du panier moyen.
-- ============================================================


-- ------------------------------------------------------------
-- 15.A Exploration
-- But : connaître la base avant de l'analyser (volume, structure,
-- qualité des données).
-- ------------------------------------------------------------

-- 15.A.1 Nombre de lignes de chaque table
-- Un COUNT(*) par table, puis UNION ALL pour empiler les 4 résultats
-- dans un seul tableau (table_name | nb_lignes).
-- UNION ALL (et pas UNION) : on ne veut pas que SQL supprime des doublons.
SELECT 'client'         AS table_name, COUNT(*) AS nb_lignes FROM client
UNION ALL
SELECT 'produit',        COUNT(*) FROM produit
UNION ALL
SELECT 'commande',       COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;

-- 15.A.2 Colonnes et types de données de chaque table
-- information_schema.columns est une vue système de PostgreSQL qui décrit
-- toutes les colonnes de toutes les tables de la base.
--   table_schema = 'public' : schéma par défaut où sont créées nos tables
--   is_nullable              : YES si la colonne accepte les NULL, NO sinon
--   ordinal_position         : ordre des colonnes tel que défini au CREATE TABLE
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;

-- 15.A.3 Valeurs manquantes (NULL) par colonne
-- COUNT(*)       compte toutes les lignes ;
-- COUNT(colonne) ne compte que les lignes où la colonne n'est PAS NULL.
-- Donc COUNT(*) - COUNT(colonne) = nombre de valeurs manquantes.
SELECT 'client' AS table_name,
       COUNT(*) - COUNT(nom)              AS nb_null_nom,
       COUNT(*) - COUNT(prenom)           AS nb_null_prenom,
       COUNT(*) - COUNT(email)            AS nb_null_email,
       COUNT(*) - COUNT(ville)            AS nb_null_ville,
       COUNT(*) - COUNT(date_inscription) AS nb_null_date_inscription
FROM client;

SELECT 'produit' AS table_name,
       COUNT(*) - COUNT(nom)       AS nb_null_nom,
       COUNT(*) - COUNT(categorie) AS nb_null_categorie,
       COUNT(*) - COUNT(prix)      AS nb_null_prix,
       COUNT(*) - COUNT(stock)     AS nb_null_stock
FROM produit;

SELECT 'commande' AS table_name,
       COUNT(*) - COUNT(client_id)     AS nb_null_client_id,
       COUNT(*) - COUNT(date_commande) AS nb_null_date_commande,
       COUNT(*) - COUNT(statut)        AS nb_null_statut
FROM commande;

SELECT 'ligne_commande' AS table_name,
       COUNT(*) - COUNT(commande_id)   AS nb_null_commande_id,
       COUNT(*) - COUNT(produit_id)    AS nb_null_produit_id,
       COUNT(*) - COUNT(quantite)      AS nb_null_quantite,
       COUNT(*) - COUNT(prix_unitaire) AS nb_null_prix_unitaire
FROM ligne_commande;

-- Interprétation 15.A :
--   Toutes les colonnes sont déclarées NOT NULL dans create_schema.sql :
--   la base refuse donc les valeurs manquantes, et on obtient 0 partout.
--   Les contraintes du schéma garantissent la qualité de ces données.


-- ------------------------------------------------------------
-- 15.B Analyse commerciale
-- ------------------------------------------------------------

-- 15.B.1 CA total, nombre de commandes, panier moyen, clients actifs
-- En une seule requête :
--   - JOIN commande / ligne_commande pour avoir les montants ;
--   - WHERE statut <> 'annulée' pour respecter la règle de calcul ;
--   - COUNT(DISTINCT c.id) : la jointure répète chaque commande autant de
--     fois qu'elle a de lignes, DISTINCT évite de la compter plusieurs fois ;
--   - panier moyen = CA / nombre de commandes ;
--   - client actif = client ayant au moins une commande non annulée.
SELECT
    SUM(lc.quantite * lc.prix_unitaire)                    AS chiffre_affaires,
    COUNT(DISTINCT c.id)                                   AS nb_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)
          / COUNT(DISTINCT c.id), 2)                       AS panier_moyen,
    COUNT(DISTINCT c.client_id)                            AS nb_clients_actifs
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- 15.B.2 Taux d'annulation des commandes
-- Ici on prend TOUTES les commandes (y compris les annulées), sinon le
-- taux serait toujours de 0 %.
--   COUNT(*) FILTER (WHERE ...) : ne compte que les lignes qui vérifient
--   la condition (syntaxe PostgreSQL).
--   100.0 (et pas 100) : force une division décimale ; avec deux entiers,
--   PostgreSQL ferait une division entière et renverrait 0.
SELECT
    COUNT(*)                                            AS nb_commandes_total,
    COUNT(*) FILTER (WHERE statut = 'annulée')          AS nb_commandes_annulees,
    ROUND(100.0 * COUNT(*) FILTER (WHERE statut = 'annulée')
          / COUNT(*), 2)                                AS taux_annulation_pct
FROM commande;

-- Interprétation 15.B :
--   - CA : argent réellement encaissé (hors commandes annulées) ;
--   - nombre de commandes : volume d'activité ;
--   - panier moyen : dépense moyenne par commande (CA / nb commandes) ;
--   - clients actifs < nombre total de clients : certains clients sont
--     inscrits mais n'ont jamais commandé ;
--   - un taux d'annulation faible indique peu de commandes perdues.


-- ------------------------------------------------------------
-- 15.C Analyse des clients
-- ------------------------------------------------------------

-- Top 10 des clients ayant généré le plus de chiffre d'affaires
--   - client -> commande -> ligne_commande : on remonte du montant au client ;
--   - INNER JOIN : les clients sans commande n'ont pas de CA, ils ne
--     peuvent pas être dans le top ;
--   - GROUP BY client puis tri décroissant sur le CA, LIMIT 10.
SELECT
    cl.id                                  AS client_id,
    cl.nom,
    cl.prenom,
    cl.ville,
    COUNT(DISTINCT c.id)                   AS nb_commandes,
    SUM(lc.quantite * lc.prix_unitaire)    AS chiffre_affaires
FROM client cl
JOIN commande c        ON c.client_id = cl.id
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY cl.id, cl.nom, cl.prenom, cl.ville
ORDER BY chiffre_affaires DESC
LIMIT 10;

-- Interprétation 15.C :
--   Ces clients sont les plus précieux pour l'entreprise : ils peuvent
--   être ciblés par un programme de fidélité ou des offres dédiées.
--   Comparer nb_commandes et chiffre_affaires montre si un client dépense
--   beaucoup parce qu'il commande souvent ou parce qu'il fait de gros paniers.


-- ------------------------------------------------------------
-- 15.D Synthèse mensuelle
-- ------------------------------------------------------------

-- DROP TABLE IF EXISTS : permet de relancer le script sans erreur
-- (sinon CREATE TABLE échoue si la table existe déjà).
DROP TABLE IF EXISTS synthese_mensuelle;

-- CREATE TABLE ... AS SELECT : crée une vraie table remplie avec le
-- résultat de la requête (contrairement à une vue, les données sont
-- stockées : c'est une "photo" à l'instant de l'exécution).
--   DATE_TRUNC('month', date) ramène chaque date au 1er du mois
--   (ex. 2025-03-17 -> 2025-03-01), ce qui permet de regrouper par mois ;
--   ::DATE convertit le résultat (timestamp) en date simple.
CREATE TABLE synthese_mensuelle AS
SELECT
    DATE_TRUNC('month', c.date_commande)::DATE           AS mois,
    COUNT(DISTINCT c.id)                                 AS nb_commandes,
    SUM(lc.quantite * lc.prix_unitaire)                  AS chiffre_affaires,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)
          / COUNT(DISTINCT c.id), 2)                     AS panier_moyen
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY DATE_TRUNC('month', c.date_commande);

-- Affichage de la synthèse, du mois le plus ancien au plus récent
SELECT * FROM synthese_mensuelle ORDER BY mois;

-- Interprétation 15.D :
-- Cette table permet de suivre mois par mois l'évolution de l'activité :
--   - nb_commandes     : le volume d'activité (combien de ventes) ;
--   - chiffre_affaires : la valeur générée ;
--   - panier_moyen     : combien un client dépense en moyenne par commande.
-- Elle permet de repérer les mois forts et les mois faibles (saisonnalité),
-- et de savoir si une hausse du CA vient de plus de commandes ou de
-- paniers plus gros.
-- Observations (résultats obtenus) :
--   - Mois le plus fort : mai 2025 (68 841,64 € de CA, 54 commandes),
--     suivi d'août (65 441,63 €) et décembre (60 655,34 €).
--   - Mois le plus faible : janvier 2025 (34 765,36 €, 29 commandes),
--     puis avril (35 932,15 €) et septembre (40 578,54 €).
--   - Tendance générale : activité en hausse sur l'année. Le 2e semestre
--     (≈ 327 700 €) dépasse le 1er (≈ 289 800 €) d'environ 13 %.
--     Le panier moyen progresse aussi : ≈ 1 200 € en janvier contre
--     1 578,81 € en octobre et 1 444,17 € en décembre. La croissance du CA
--     vient donc surtout de paniers plus gros, pas seulement de plus de
--     commandes (octobre : seulement 34 commandes mais 53 679,61 € de CA).
--
-- Résultats clés de l'exercice 15 :
--   - 100 clients, 65 produits, 500 commandes, 1 547 lignes, 0 valeur manquante ;
--   - CA total 617 494,76 € sur 484 commandes, panier moyen 1 275,82 € ;
--   - 90 clients actifs sur 100 (les clients 91 à 100 n'ont jamais commandé :
--     cible possible pour une relance marketing) ;
--   - taux d'annulation 3,20 % (16 commandes sur 500) ;
--   - meilleur client : Alice Dubois (Nice), 17 169,00 € sur 11 commandes.


