# Fonctionnalité : Ajouter un point de donnée (bateau)

## Description

Cette fonctionnalité permet d'ajouter un nouveau point de donnée lié à un bateau dans la base de données via un formulaire web. Elle capture toutes les informations essentielles d'un navire incluant ses caractéristiques techniques, sa position géographique et ses données de navigation.

## Structure des fichiers

```
├── ajouter_mon_bateau.html    # Interface utilisateur (formulaire)
├── js/
│   └── ajouter_bateau.js      # Logique côté client
├── php/
│   ├── traitement.php         # Traitement des données et insertion en BDD
│   └── get_etats.php         # Récupération des statuts disponibles
└── css/
    └── main.css              # Styles (non fourni)
```

## Fonctionnalités

### Données collectées

Le formulaire capture les informations suivantes :

**Identification du navire :**
- Nom du navire
- MMSI (9 chiffres obligatoires)
- État/Statut (sélection depuis la base de données)

**Caractéristiques physiques :**
- Longueur (en mètres)
- Largeur (en mètres)
- Tirant d'eau (en mètres)

**Données de navigation :**
- Horodatage (date et heure)
- Position GPS (latitude/longitude avec précision à 6 décimales)
- COG - Course Over Ground (cap par rapport au fond, en degrés)
- Cap réel/Heading (en degrés)
- SOG - Speed Over Ground (vitesse par rapport au fond, en nœuds)

### Validation des données

**Côté client (JavaScript) :**
- Vérification de la présence de tous les champs requis
- Validation du format MMSI (9 chiffres)
- Contrôles de type (numérique, date, etc.)

**Côté serveur (PHP) :**
- Double validation de tous les champs
- Validation spécifique du MMSI avec regex
- Vérification de l'ID statut (entre 1 et 15)
- Gestion des erreurs avec rollback de transaction

## Base de données

### Table Bateaux
```sql
CREATE TABLE Bateaux (
    mmsi INT(9) PRIMARY KEY,
    nom VARCHAR(255),
    id_statut INT,
    longueur DECIMAL(8,2),
    largeur DECIMAL(8,2),
    tirant_eau DECIMAL(8,2),
    horodatage DATETIME,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    sog DECIMAL(5,1),
    cog DECIMAL(5,1),
    cap_reel DECIMAL(5,1)
);
```

### Table Statut
```sql
CREATE TABLE Statut (
    id INT PRIMARY KEY,
    nom VARCHAR(255)
);
```

## Configuration technique

### Prérequis
- Serveur web avec PHP 7.0+
- Base de données MySQL
- Extension PHP PDO activée

### Configuration de la base de données
Modifier les paramètres de connexion dans `traitement.php` et `get_etats.php` :
```php
$pdo = new PDO("mysql:host=localhost;dbname=votre_db;charset=utf8", "utilisateur", "mot_de_passe");
```

## Utilisation

1. **Accès au formulaire :** Ouvrir `ajouter_mon_bateau.html` dans le navigateur
2. **Remplissage :** Compléter tous les champs obligatoires
3. **Validation :** Cliquer sur "Valider" pour soumettre
4. **Retour :** Message de succès ou d'erreur affiché sous le formulaire

## Fonctionnalités avancées

### Chargement dynamique des statuts
- Les options de statut sont chargées automatiquement depuis la base de données
- Affichage du nom et de l'ID pour clarification
- Gestion des erreurs de chargement

### Soumission AJAX
- Soumission asynchrone sans rechargement de page
- Feedback immédiat à l'utilisateur
- Conservation des données en cas d'erreur partielle

### Gestion d'erreurs robuste
- Logging côté serveur pour le débogage
- Messages d'erreur utilisateur conviviaux
- Rollback automatique des transactions échouées

## Sécurité

- Échappement automatique des données via PDO
- Validation stricte des types de données
- Protection contre l'injection SQL
- Vérification côté serveur obligatoire

## Débogage

Les logs d'erreur sont activés dans le code PHP. Vérifier les logs du serveur web pour diagnostiquer les problèmes :
- Données reçues via POST
- Données préparées pour insertion
- Erreurs PDO et exceptions

## Améliorations possibles

- Validation de coordonnées GPS (plages de valeurs réalistes)
- Upload de fichiers pour plans de navire
- Historique des modifications
- Interface d'administration pour les statuts
- Géolocalisation automatique
- Validation de cohérence des données (vitesse/cap)

## Support

En cas de problème, vérifier :
1. La connexion à la base de données
2. Les logs d'erreur PHP
3. La console développeur du navigateur
4. Les permissions de fichiers sur le serveur