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