import pandas as pd
import joblib

def predict_cluster_interactif():
    print("\n=== Prédiction de cluster pour un navire ===")

    try:
        lat = float(input("LAT (latitude) : "))
        lon = float(input("LON (longitude) : "))
        sog = float(input("SOG (Speed Over Ground) : "))
        cog = float(input("COG (Course Over Ground) : "))
    except ValueError:
        print("❌ Entrée invalide.")
        return

    navire = {
        "LAT": lat,
        "LON": lon,
        "SOG": sog,
        "COG": cog
    }

    df_input = pd.DataFrame([navire])

    try:
        model = joblib.load("model.pkl")
        # Juste pour les features utilisées dans le clustering
        X_input = df_input[['LAT', 'LON', 'SOG', 'COG']]
        cluster = model.predict(X_input)[0]
        print(f"\n✅ Ce navire appartient au cluster : {cluster}")
    except Exception as e:
        print(f"❌ Erreur : {e}")

if __name__ == "__main__":
    predict_cluster_interactif()