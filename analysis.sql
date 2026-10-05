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
