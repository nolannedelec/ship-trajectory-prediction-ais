# Importation des bibliothèques nécessaires
import pandas as pd          # Pour manipuler des données tabulaires (DataFrame)
import joblib                # Pour charger le modèle de clustering enregistré
import json                  # Pour formater la sortie en JSON
import pymysql               # Pour se connecter à une base de données MySQL

# Fonction principale
def main():
    try:
        # Connexion à la base de données MySQL avec pymysql
        conn = pymysql.connect(
            host='localhost',
            user='etu0209',           # Nom d'utilisateur MySQL (à adapter si besoin)
            password='xxcthgkd',      # Mot de passe (à adapter)
            database='etu0209'        # Nom de la base de données
        )

        # Requête SQL pour récupérer les données nécessaires au clustering
        query = "SELECT mmsi, latitude, longitude, sog, cog FROM Bateaux"

        # Exécution de la requête et chargement dans un DataFrame
        df = pd.read_sql(query, conn)

        # Vérifie que le DataFrame n'est pas vide
        if df.empty:
            print(json.dumps({"error": "Aucun bateau trouvé dans la base"}))
            return  # Arrête l'exécution s’il n’y a pas de données

        # Chargement du modèle de clustering (pré-entraîne avec scikit-learn)
        model = joblib.load("../model.pkl")  # Le fichier doit être présent dans le dossier parent

        # Préparation des colonnes nécessaires au modèle
        X = df[['latitude', 'longitude', 'sog', 'cog']]

        # Prédiction du cluster pour chaque bateau
        df['cluster'] = model.predict(X)

        # Préparation du résultat pour affichage sur une carte
        result = df[['mmsi', 'latitude', 'longitude', 'cluster']].rename(columns={
            'latitude': 'lat',
            'longitude': 'lon'
        }).to_dict(orient='records')  # Convertit chaque ligne en dictionnaire

        # Affiche le résultat en JSON (utilisé par PHP ou JS)
        print(json.dumps(result))

    except Exception as e:
        # En cas d’erreur (connexion, SQL, chargement, etc.), affiche un message d'erreur JSON
        print(json.dumps({"error": str(e)}))

# Point d’entrée du script
if __name__ == "__main__":
    main()
