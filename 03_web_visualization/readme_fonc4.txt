# Fonctionnalité 4 : Clustering de Bateaux

## Description

Cette fonctionnalité permet de regrouper automatiquement les bateaux selon leur comportement de navigation en utilisant un algorithme de clustering (machine learning). Elle offre deux modes d'utilisation :

1. **Mode global** : Clustering de tous les bateaux de la base de données
2. **Mode interactif** : Classification d'un nouveau bateau basé sur ses coordonnées et paramètres de navigation

## Architecture

```
clustering/
├── cluster.html              # Interface utilisateur avec carte interactive
├── php/
│   ├── predictCluster.php    # API pour le clustering global
│   └── interactif.php        # API pour le clustering interactif
├── python/
│   ├── cluster_all.py        # Script Python pour clustering global
│   ├── script_interactif.py  # Script Python pour clustering interactif
│   └── model.pkl            # Modèle de clustering pré-entraîné
└── css/
    └── main.css             # Styles de l'interface
```

## Technologies Utilisées

- **Frontend** : HTML5, CSS3, JavaScript, Leaflet.js (cartographie)
- **Backend** : PHP 7.4+, Python 3.x
- **Base de données** : MySQL
- **Machine Learning** : scikit-learn, pandas, joblib
- **Visualisation** : OpenStreetMap via Leaflet

## Prérequis

### Serveur
- PHP 7.4 ou supérieur
- Python 3.6 ou supérieur
- MySQL 5.7 ou supérieur
- Serveur web (Apache/Nginx)

### Dépendances Python
```bash
pip install pandas joblib pymysql scikit-learn
```

### Base de données
Table `Bateaux` avec les colonnes :
- `mmsi` (VARCHAR) - Identifiant unique du bateau
- `nom` (VARCHAR) - Nom du bateau
- `latitude` (DECIMAL) - Position latitude
- `longitude` (DECIMAL) - Position longitude
- `sog` (DECIMAL) - Vitesse sur le fond (Speed Over Ground)
- `cog` (DECIMAL) - Cap sur le fond (Course Over Ground)
- `longueur` (DECIMAL) - Longueur du bateau
- `largeur` (DECIMAL) - Largeur du bateau
- `tirant_eau` (DECIMAL) - Tirant d'eau

## Installation

### 1. Configuration de la base de données

Modifiez les paramètres de connexion dans `cluster_all.py` :

```python
conn = pymysql.connect(
    host='localhost',
    user='votre_utilisateur',
    password='votre_mot_de_passe',
    database='votre_base'
)
```

### 2. Placement des fichiers

Placez les fichiers dans votre répertoire web :
```
/var/www/html/projet/
├── cluster.html
├── php/
├── python/
└── css/
```

### 3. Permissions

Assurez-vous que le serveur web peut exécuter les scripts Python :
```bash
chmod +x python/cluster_all.py
chmod +x python/script_interactif.py
```

## Utilisation

### Mode Global (Clustering de tous les bateaux)

1. Accédez à `cluster.html` dans votre navigateur
2. La carte se charge automatiquement avec tous les bateaux colorés par cluster
3. Les couleurs représentent différents groupes de comportement de navigation
4. Cliquez sur un point pour voir les détails du bateau (MMSI, cluster)

### Mode Interactif (Classification d'un nouveau bateau)

Envoyez une requête POST à `php/interactif.php` avec les paramètres :

```json
{
    "latitude": 28.5,
    "longitude": -90.0,
    "sog": 12.5,
    "cog": 180.0
}
```

**Exemple avec curl :**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"latitude":28.5,"longitude":-90.0,"sog":12.5,"cog":180.0}' \
  http://votre-serveur.com/php/interactif.php
```

**Réponse :**
```json
[{
    "mmsi": "interactif",
    "lat": 28.5,
    "lon": -90.0,
    "cluster": 2
}]
```

## API Endpoints

### GET /php/predictCluster.php
Retourne tous les bateaux avec leur cluster assigné.

**Réponse :**
```json
[
    {
        "mmsi": "123456789",
        "lat": 28.5,
        "lon": -90.0,
        "cluster": 0
    },
    ...
]
```

### POST /php/interactif.php
Classifie un nouveau bateau dans un cluster.

**Paramètres requis :**
- `latitude` : Latitude (-90 à 90)
- `longitude` : Longitude (-180 à 180)
- `sog` : Vitesse (0 à 50 nœuds)
- `cog` : Cap (0 à 359 degrés)

### GET /php/interactif.php
Mode diagnostic pour tester la configuration.

## Validation des Données

### Contraintes de validation :
- **Latitude** : -90 ≤ lat ≤ 90
- **Longitude** : -180 ≤ lon ≤ 180
- **SOG** : 0 ≤ sog ≤ 50
- **COG** : 0 ≤ cog < 360

## Gestion d'Erreurs

### Erreurs côté PHP :
- Code 400 : Paramètres manquants ou invalides
- Code 500 : Erreur serveur/base de données
- Code 405 : Méthode HTTP non autorisée

### Erreurs côté Python :
- Erreur de conversion des paramètres
- Fichier modèle introuvable
- Erreur de connexion base de données

### Exemple de réponse d'erreur :
```json
{
    "error": "Paramètres manquants (latitude, longitude, sog, cog requis)",
    "received": {...}
}
```

## Personnalisation

### Modification des couleurs de clusters

Dans `cluster.html`, modifiez le tableau `clusterColors` :

```javascript
const clusterColors = [
    "#e41a1c", "#377eb8", "#4daf4a", "#984ea3",
    "#ff7f00", "#ffff33", "#a65628", "#f781bf", "#999999"
];
```

### Changement du modèle de clustering

Remplacez `model.pkl` par votre propre modèle entraîné avec scikit-learn, en veillant à utiliser les mêmes features : `['latitude', 'longitude', 'sog', 'cog']`.

## Débogage

### Logs PHP
Les erreurs sont loggées via `error_log()`. Consultez les logs du serveur web.

### Test de connectivité Python
```bash
python3 --version
python3 -c "import pandas, joblib, pymysql; print('Dépendances OK')"
```

### Test des scripts
```bash
cd python/
python3 cluster_all.py
python3 script_interactif.py 28.5 -90.0 12.5 180.0
```

## Sécurité

- Validation stricte des paramètres d'entrée
- Échappement des commandes shell avec `escapeshellarg()`
- Headers CORS configurables
- Gestion des erreurs sans exposition d'informations sensibles

## Performance

- Les requêtes SQL utilisent les index sur les colonnes de position
- Le modèle de clustering est chargé une seule fois par exécution
- Cache possible côté navigateur pour les données statiques

## Contribution

Pour contribuer à cette fonctionnalité :

1. Respectez la structure des fichiers existante
2. Validez les paramètres d'entrée
3. Gérez les erreurs de façon appropriée
4. Documentez les modifications apportées
5. Testez sur différents jeux de données

## Support

En cas de problème :
1. Vérifiez les logs du serveur web
2. Testez la connectivité à la base de données
3. Vérifiez la présence du fichier `model.pkl`
4. Validez les dépendances Python installées