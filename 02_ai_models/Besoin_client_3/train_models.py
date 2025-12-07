# Importation des bibliothèques
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

def train_and_save_model(df, horizon_value):
    print(f"\n=== Entraînement pour horizon {horizon_value} minutes ===")

    df = df[df['Heading'] != 511].copy()
    df['LAT_target'] = pd.to_numeric(df['LAT_target'], errors='coerce')
    df['LON_target'] = pd.to_numeric(df['LON_target'], errors='coerce')
    df = df.dropna(subset=features + target)

    X = df[features]
    y = df[target]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, shuffle=False)

    rf = RandomForestRegressor(
        n_estimators=100,
        max_depth=10,
        min_samples_split=20,
        min_samples_leaf=10,
        random_state=42,
        n_jobs=-1
    )

    model = MultiOutputRegressor(rf)
    model.fit(X_train, y_train)

    # Sauvegarde du modèle
    model_filename = f"model_rf_{horizon_value}min.joblib"
    joblib.dump(model, model_filename)
    print(f" Modèle sauvegardé : {model_filename}")

    #  Sauvegarde des jeux de données utiles pour l'affichage
    joblib.dump((X_test, y_test, df.loc[X_test.index]['MMSI'].reset_index(drop=True)), f"test_data_{horizon_value}min.joblib")

    print(f" Données test sauvegardées : test_data_{horizon_value}min.joblib")


# Définition des colonnes d'entraînement
features = [
    'LAT', 'LON', 'SOG', 'COG', 'Heading',
    'LAT_lag1', 'LON_lag1', 'SOG_lag1', 'COG_lag1', 'Heading_lag1',
    'LAT_lag2', 'LON_lag2', 'SOG_lag2', 'COG_lag2', 'Heading_lag2', 'horizon'
]
target = ['LAT_target', 'LON_target']

df_5 = pd.read_csv('/Users/nolanjauffrit/Desktop/annee_3/projet_IA/df_5_fin.csv')
df_10 = pd.read_csv('/Users/nolanjauffrit/Desktop/annee_3/projet_IA/df_10_fin.csv')
df_15 = pd.read_csv('/Users/nolanjauffrit/Desktop/annee_3/projet_IA/df_15_fin.csv')

train_and_save_model(df_5, 5)
train_and_save_model(df_10, 10)
train_and_save_model(df_15, 15)