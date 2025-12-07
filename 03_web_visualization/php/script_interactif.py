# Importation des bibliothèques nécessaires
import pandas as pd          # Pour gérer les données tabulaires
import joblib                # Pour charger le modèle ML enregistré
import sys                   # Pour lire les arguments de la ligne de commande
import json                  # Pour formater la sortie au format JSON

# Fonction principale pour exécuter la prédiction
def predict_cluster_interactif():
    try:
        # Vérifie que 4 arguments sont fournis (lat, lon, sog, cog)
        if len(sys.argv) != 5:
            print(json.dumps({"error": "Usage: python script_interactif.py <latitude> <longitude> <sog> <cog>"}))
            return

        # Conversion des arguments en flottants
        lat = float(sys.argv[1])
        lon = float(sys.argv[2])
        sog = float(sys.argv[3])
        cog = float(sys.argv[4])

        # Création d’un dictionnaire avec les données du navire
        navire = {
            "LAT": lat,
            "LON": lon,
            "SOG": sog,
            "COG": cog
        }

        # Transformation en DataFrame pour compatibilité avec le modèle
        df_input = pd.DataFrame([navire])

        # Chargement du modèle de clustering enregistré avec joblib
        model = joblib.load("model.pkl")

        # Sélection des colonnes utilisées par le modèle
        X_input = df_input[['LAT', 'LON', 'SOG', 'COG']]

        # Prédiction du cluster
        cluster = model.predict(X_input)[0]

        # Résultat au format liste (compatible avec le JS ou les cartes Leaflet)
        result = [{
            "mmsi": "interactif",  # Identifiant générique (ou personnalisable)
            "lat": lat,
            "lon": lon,
            "cluster": int(cluster)
        }]

        # Affiche le résultat en JSON (utilisé par un script externe)
        print(json.dumps(result))

    except ValueError as e:
        # Gestion des erreurs de conversion (ex: non-nombre en entrée)
        print(json.dumps([{"error": f"Erreur de conversion : {str(e)}"}]))
    except FileNotFoundError:
        # Si le fichier du modèle n'existe pas
        print(json.dumps([{"error": "Le fichier model.pkl n'a pas été trouvé"}]))
    except Exception as e:
        # Autre erreur générale
        print(json.dumps([{"error": f"Erreur : {str(e)}"}]))

# Exécution de la fonction si le script est lancé en ligne de commande
if __name__ == "__main__":
    predict_cluster_interactif()
