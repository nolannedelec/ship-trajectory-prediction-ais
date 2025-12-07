# 1. Importation des bibliothèques
import pandas as pd
import numpy as np
import joblib
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from geopy.distance import geodesic
import folium
from branca.element import Template, MacroElement

def evaluate_and_visualize_model(horizon_value):
    print(f"\n=== Évaluation du modèle sauvegardé - {horizon_value} min ===")

    # Chargement
    model = joblib.load(f"model_rf_{horizon_value}min.joblib")
    X_test, y_test, mmsi_test = joblib.load(f"test_data_{horizon_value}min.joblib")

    y_test = y_test.reset_index(drop=True)
    mmsi_test = mmsi_test.reset_index(drop=True)

    y_test_pred = model.predict(X_test)

    # RMSE
    rmse_lat = np.sqrt(mean_squared_error(y_test['LAT_target'], y_test_pred[:, 0]))
    rmse_lon = np.sqrt(mean_squared_error(y_test['LON_target'], y_test_pred[:, 1]))
    print(f" RMSE Test ➤ LAT: {rmse_lat:.6f}, LON: {rmse_lon:.6f}")

    # Erreurs géographiques
    errors = [geodesic((true[0], true[1]), (pred[0], pred[1])).meters for true, pred in zip(y_test.values, y_test_pred)]
    print(f" Erreur géographique moyenne : {np.mean(errors):.2f} m")
    print(f" Erreur géographique médiane : {np.median(errors):.2f} m")

     # Préparation pour affichage
    y_pred_df = pd.DataFrame(y_test_pred, columns=['LAT_pred', 'LON_pred'])
    results_df = pd.concat([X_test.reset_index(drop=True)[['horizon']], y_test, y_pred_df, mmsi_test.rename("MMSI")], axis=1)

    # Choix de MMSI
    mmsi_unique = results_df['MMSI'].unique()
    selected_mmsi = np.random.choice(mmsi_unique, size=min(2, len(mmsi_unique)), replace=False)

    # 🔎 Dernière position prédite
    for mmsi in selected_mmsi:
        last_row = results_df[results_df["MMSI"] == mmsi].sort_values(by='horizon').iloc[-1]
        lat_pred = last_row["LAT_pred"]
        lon_pred = last_row["LON_pred"]
        lat_real = last_row["LAT_target"]
        lon_real = last_row["LON_target"]
        
        print(f"\n Dernière position prédite pour le navire MMSI {mmsi} (Horizon {horizon_value} min):")
        print(f"  → Prédiction : Latitude = {lat_pred:.5f}, Longitude = {lon_pred:.5f}")
        print(f"  → Réelle     : Latitude = {lat_real:.5f}, Longitude = {lon_real:.5f}")


# Phase 2 : Évaluation & affichage
evaluate_and_visualize_model(5)
evaluate_and_visualize_model(10)
evaluate_and_visualize_model(15)