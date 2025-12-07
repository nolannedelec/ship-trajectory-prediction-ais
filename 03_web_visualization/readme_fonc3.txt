# NaviTrack - Visualisation des Trajectoires de Bateaux

## Nouvelles Fonctionnalités Ajoutées

### 1. Tableau Interactif Compact
- **Colonnes optimisées** : Tailles de colonnes cohérentes avec gestion du contenu
- **Boutons radio** : Sélection interactive des bateaux

### 2. Visualisation des Trajectoires
- **Sélection par bouton radio** : Cliquez sur un bateau pour voir sa trajectoire complète
- **Ligne de trajectoire** : Affichage de tous les points de passage du bateau
- **Marqueurs spéciaux** :
  - 🟢 Point de départ (vert)
  - 🔴 Point d'arrivée (rouge)
  - 🔵 Points intermédiaires (bleu)

### 3. Interface Utilisateur Améliorée
- **Informations du bateau sélectionné** : Panneau d'informations contextuel
- **Bouton d'effacement** : Retour à la vue générale
- **Compteur de bateaux** : Affichage du nombre total de bateaux
- **Responsive design** : Adaptation mobile et desktop

## Fichiers Modifiés/Ajoutés

### Nouveaux Fichiers PHP
- `get_trajectoire.php` : Récupération des trajectoires complètes par MMSI
- `get_bateaux.php` (amélioré) : Optimisation des requêtes et formatage des données

### Fichiers Modifiés
- `visualisation.html` : Nouveau design du tableau et interface
- `main.css` : Styles pour le tableau compact et interface
- `visualisation.js` : Logique de sélection et affichage des trajectoires

## Utilisation

### 1. Sélectionner un Bateau
1. Cliquez sur le bouton radio à côté du bateau souhaité
2. La trajectoire s'affiche automatiquement sur la carte

### 2. Visualiser la Trajectoire
- **Ligne bleue** : Trajectoire complète du bateau
- **Marqueur vert** : Point de départ
- **Marqueur rouge** : Point d'arrivée
- **Hover** : Informations détaillées au survol

### 3. Navigation
- **Effacer la sélection** : Bouton rouge pour revenir à la vue générale
- **Zoom automatique** : La carte s'adapte à la trajectoire sélectionnée
- **Légende** : Affichage des différents éléments de la trajectoire

## Structure de la Base de Données

Le système utilise la table `Bateaux` avec les colonnes :
- `MMSI` : Identifiant unique du bateau
- `nom` : Nom du bateau
- `latitude`, `longitude` : Coordonnées GPS
- `SOG` : Vitesse sur le fond
- `COG` : Cap sur le fond
- `horodatage` : Timestamp de la position

## Fonctionnalités Techniques

### Optimisations
- **Requêtes SQL optimisées** : Récupération efficace des dernières positions
- **Groupement par MMSI** : Évite les doublons dans le tableau
- **Formatage des données** : Nombres décimaux arrondis pour l'affichage

### Responsive Design
- **Adaptation mobile** : Interface optimisée pour tous les écrans
- **Scroll adaptatif** : Gestion intelligente du défilement
- **Tailles de colonnes flexibles** : Adaptation automatique

### Gestion d'Erreurs
- **Erreurs de connexion** : Messages d'erreur explicites
- **Données manquantes** : Gestion des cas d'absence de trajectoire
- **Validation des données** : Vérification des paramètres

## Installation

1. Placez les fichiers dans votre répertoire web
2. Assurez-vous que les paramètres de base de données sont corrects dans les fichiers PHP
3. Vérifiez que la table `Bateaux` contient des données
4. Accédez à `visualisation.html` dans votre navigateur

## Personnalisation

### Modifier l'Apparence
- Éditez `main.css` pour changer les couleurs et styles
- Modifiez les classes CSS pour ajuster les tailles de colonnes
- Personnalisez les couleurs des trajectoires dans `visualisation.js`

### Ajuster le Comportement
- Changez le nombre de lignes affichées dans `.table_wrapper { max-height: 200px; }`
- Modifiez les couleurs des marqueurs dans la fonction `afficherTrajectoire()`
- Adaptez le zoom automatique dans `calculateZoom()`

## Dépendances

- **Plotly.js** : Librairie de visualisation (CDN)
- **PHP/MySQL** : Backend pour les données
- **CSS/JavaScript moderne** : Interface utilisateur

## Support

Pour toute question ou problème, vérifiez :
1. La connexion à la base de données
2. La structure de la table `Bateaux`
3. Les permissions des fichiers PHP
4. La console développeur du navigateur pour les erreurs JavaScript