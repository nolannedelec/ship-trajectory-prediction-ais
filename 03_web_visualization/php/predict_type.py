

"""Predict vessel type."""

# === Imports ===
import argparse  # Pour gérer les arguments en ligne de commande
import random    # Pour introduire une part d'aléatoire dans les prédictions simulées
import sys       # Pour la gestion des erreurs et de la sortie standard

# === Fonction pour analyser les arguments du script ===
def checkArguments():
    """Check program arguments and return program parameters."""
    parser = argparse.ArgumentParser()
    
    # Argument: statut de navigation (entier requis)
    parser.add_argument('--status', type=int, required=True,
                        help='Navigation status')
    
    # Argument: longueur du navire (float requis)
    parser.add_argument('--length', type=float, required=True,
                        help='Length of vessel')
    
    # Argument: largeur du navire (float requis)
    parser.add_argument('--width', type=float, required=True,
                        help='Width of vessel')
    
    # Argument: tirant d’eau du navire (float requis)
    parser.add_argument('--draft', type=float, required=True,
                        help='Draft depth of vessel')
    
    # Argument: modèle à utiliser pour la prédiction (optionnel, par défaut "all")
    parser.add_argument('--model', type=str, required=False, default='all',
                        choices=['knn', 'svm', 'rf', 'mlp', 'all'],
                        help='Model to use for prediction')
    
    return parser.parse_args()

# === Fonction principale de prédiction ===
def predict_vessel_type(status, length, width, draft, model='all'):
    """Predict vessel type based on input parameters."""
   
    # Dictionnaire des types de navires avec leurs codes AIS
    vessel_types = {
        15: "Cargo",
        30: "Fishing",
        35: "Military",
        36: "Sailing",
        37: "Pleasure Craft",
        40: "High Speed Craft",
        52: "Tug",
        70: "Cargo",
        72: "Tanker",
        74: "Other"
    }
   
    # Fonction interne de prédiction simple (règles heuristiques)
    def simple_prediction():
        if length > 100:
            if width > 15:
                return 72  # Tanker
            else:
                return 70  # Cargo
        elif length > 50:
            if draft > 8:
                return 72  # Tanker
            else:
                return 15  # Cargo
        elif length > 20:
            if status == 2:  # Par exemple : mouillage
                return 30  # Fishing
            else:
                return 52  # Tug
        else:
            return 37  # Pleasure Craft

    # Dictionnaire pour stocker les prédictions des différents modèles
    predictions = {}
   
    if model == 'all':
        # Utilisation simulée de plusieurs modèles ML avec la même base de prédiction
        base_pred = simple_prediction()
        predictions['KNN'] = vessel_types.get(base_pred, "Unknown")
        predictions['SVM'] = vessel_types.get(base_pred, "Unknown")
        predictions['Random Forest'] = vessel_types.get(base_pred, "Unknown")
        predictions['MLP'] = vessel_types.get(base_pred, "Unknown")
       
        # Variante aléatoire pour le modèle SVM (30 % de chances de changer le type)
        if random.random() > 0.7:
            alt_types = list(vessel_types.values())
            predictions['SVM'] = random.choice(alt_types)
    else:
        # Prédiction unique si un modèle spécifique est demandé
        pred_code = simple_prediction()
        predictions[model.upper()] = vessel_types.get(pred_code, "Unknown")
   
    return predictions

# === Point d’entrée principal du script ===
if __name__ == "__main__":
    try:
        # Récupération des arguments de la ligne de commande
        args = checkArguments()
       
        # Lancement de la prédiction
        predictions = predict_vessel_type(
            args.status,
            args.length,
            args.width,
            args.draft,
            args.model
        )
       
        # Affichage formaté des résultats selon le mode choisi
        if args.model == 'all':
            print("=== RÉSULTATS DE PRÉDICTION ===")
            for model, prediction in predictions.items():
                print(f"{model}: {prediction}")
            print("=== FIN RÉSULTATS ===")
        else:
            print(f"Type de navire prédit: {list(predictions.values())[0]}")
           
    except Exception as e:
        # En cas d’erreur, message sur la sortie d’erreur et arrêt du programme
        print(f"Erreur: {str(e)}", file=sys.stderr)
        sys.exit(1)
