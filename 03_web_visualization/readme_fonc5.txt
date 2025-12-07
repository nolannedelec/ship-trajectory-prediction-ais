# NaviTrack - Système de Prédiction Maritime

## 📋 Description

NaviTrack est un système web de prédiction maritime qui utilise l'intelligence artificielle pour :
- **Prédire les trajectoires** des navires en temps réel
- **Classifier le type** des bateaux selon leurs caractéristiques
- **Visualiser** les données AIS sur une carte interactive

Le système analyse les données AIS (Automatic Identification System) pour fournir des prédictions précises basées sur l'apprentissage automatique.

## 🚀 Fonctionnalités Principales

### 1. Prédiction de Trajectoire
- Calcul de la position future d'un navire (5, 10 ou 15 minutes)
- Visualisation sur carte interactive avec Leaflet
- Prise en compte de la vitesse, du cap et de l'historique

### 2. Classification de Type
- Identification automatique du type de navire
- Analyse basée sur les dimensions et caractéristiques
- Niveau de confiance de la prédiction

### 3. Interface Web Interactive
- Sélection intuitive des navires
- Cartes en temps réel
- Export des résultats

## 🛠️ Architecture Technique

### Frontend
- **HTML5/CSS3/JavaScript** - Interface utilisateur
- **Leaflet.js** - Cartographie interactive
- **Fetch API** - Communication avec le backend

### Backend
- **PHP** - Serveur web et API
- **Python** - Scripts d'intelligence artificielle
- **MySQL** - Base de données AIS

### Structure des Fichiers
```
project/
├── php/
│   ├── predict_traj.php      # API prédiction trajectoire
│   ├── predict_type.php      # API classification type
│   ├── get_bateaux.php       # API récupération navires
│   └── get_bateaux2.php      # API alternative navires
├── js/
│   ├── main.js               # Logique principale
│   ├── prediction_type.js    # Interface prédiction type
│   └── trajectory.js         # Gestion trajectoires
├── python/
│   └── predict_trajectory.py # Script IA trajectoire
└── html/
    ├── index.html
    ├── prediction_type.html
    └── typetrajectoire.html
```

## 📊 Base de Données

### Table `Bateaux`
```sql
- MMSI (VARCHAR) - Identifiant unique navire
- nom (VARCHAR) - Nom du navire
- longueur (DECIMAL) - Longueur en mètres
- largeur (DECIMAL) - Largeur en mètres
- tirant_eau (DECIMAL) - Tirant d'eau en mètres
- latitude (DECIMAL) - Position latitude
- longitude (DECIMAL) - Position longitude
- SOG (DECIMAL) - Vitesse sur le fond
- COG (DECIMAL) - Cap sur le fond
- cap_reel (DECIMAL) - Cap réel
- horodatage (DATETIME) - Timestamp
```

## 🔧 Installation

### Prérequis
- Serveur web Apache/Nginx
- PHP 7.4+
- Python 3.8+
- MySQL 5.7+
- Extensions PHP : PDO, JSON

### Configuration Base de Données
```php
$host = 'localhost';
$dbname = 'votre_db';
$user = 'votre_user';
$password = 'votre_password';
```

### Dépendances Python
```bash
pip install numpy pandas scikit-learn
```

## 🚀 Utilisation

### 1. Prédiction de Trajectoire

```javascript
// Sélection d'un navire
const selectedBoat = {
    mmsi: "123456789",
    horizon: 10 // minutes
};

// Appel API
fetch('/php/predict_traj.php', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: `mmsi=${selectedBoat.mmsi}&horizon=${selectedBoat.horizon}`
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        displayTrajectory(data.data);
    }
});
```

### 2. Classification de Type

```javascript
// Données navire pour classification
const vesselData = {
    mmsi: "123456789",
    length: 150,
    width: 25,
    draft: 8,
    sog: 12
};

// Appel API
fetch('/php/predict_type.php', {
    method: 'POST',
    body: new FormData(vesselData)
})
.then(response => response.json())
.then(data => {
    console.log('Type prédit:', data.data.predicted_type);
});
```

## 📡 APIs

### GET `/php/get_bateaux.php`
Récupère la liste des navires avec leur dernière position.

**Réponse :**
```json
[
    {
        "MMSI": "123456789",
        "nom": "VESSEL_NAME",
        "latitude": "45.123456",
        "longitude": "2.654321",
        "SOG": "12.5",
        "horodatage": "2024-01-15 10:30:00"
    }
]
```

### POST `/php/predict_traj.php`
Prédit la trajectoire future d'un navire.

**Paramètres :**
- `mmsi` : Identifiant du navire
- `horizon` : Horizon de prédiction (5, 10, 15 minutes)

**Réponse :**
```json
{
    "success": true,
    "data": {
        "mmsi": "123456789",
        "current_position": {
            "latitude": 45.123,
            "longitude": 2.654
        },
        "predicted_position": {
            "latitude": 45.125,
            "longitude": 2.658
        },
        "horizon_minutes": 10
    }
}
```

### POST `/php/predict_type.php`
Classifie le type d'un navire.

**Paramètres :**
- `mmsi` : Identifiant
- `length` : Longueur
- `width` : Largeur
- `draft` : Tirant d'eau
- `sog` : Vitesse

**Réponse :**
```json
{
    "success": true,
    "data": {
        "predicted_type": "Cargo",
        "confidence": 0.87,
        "all_probabilities": {
            "Cargo": 0.87,
            "Tanker": 0.08,
            "Container": 0.03
        }
    }
}
```

## 🛡️ Sécurité

### Mesures Implémentées
- **Validation des paramètres** côté serveur
- **Requêtes préparées** (PDO) contre l'injection SQL
- **Échappement des commandes** shell
- **Gestion CORS** pour les API
- **Validation des types** de données

### Exemple de Validation
```php
// Validation MMSI
if (!is_numeric($mmsi)) {
    throw new Exception('MMSI invalide');
}

// Validation horizon
if (!in_array((int)$horizon, [5, 10, 15])) {
    throw new Exception('Horizon invalide');
}
```

## 🔍 Débogage

### Logs Activés
```php
ini_set('display_errors', 1);
error_reporting(E_ALL);
error_log("Debug: " . $message);
```

### Messages d'Erreur Détaillés
Le système fournit des informations de débogage complètes :
- Méthode HTTP utilisée
- Données POST/GET reçues
- Sortie brute des scripts Python
- Traces d'exécution

## 📈 Performance

### Optimisations
- **Cache des requêtes** fréquentes
- **Index sur MMSI** et horodatage
- **Limitation des résultats** SQL
- **Compression** des réponses JSON

### Monitoring
```php
$start_time = microtime(true);
// ... traitement ...
$execution_time = microtime(true) - $start_time;
error_log("Temps d'exécution: " . $execution_time . "s");
```

## 🤝 Contribution

### Standards de Code
- **PSR-4** pour PHP
- **ES6+** pour JavaScript
- **Commentaires** détaillés
- **Gestion d'erreurs** complète

### Tests
- Tests unitaires pour les APIs
- Validation des prédictions
- Tests d'intégration frontend/backend

## 📜 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- **Issues GitHub** : Problèmes techniques
- **Documentation** : Wiki du projet
- **Email** : support@navitrack.com

## 🔄 Mises à Jour

### Version Actuelle : 1.0.0
- Prédiction de trajectoire fonctionnelle
- Classification de type implémentée
- Interface web responsive
- APIs REST complètes

### Roadmap
- [ ] Prédictions multi-navires
- [ ] API GraphQL
- [ ] Application mobile
- [ ] Analyse temps réel avancée