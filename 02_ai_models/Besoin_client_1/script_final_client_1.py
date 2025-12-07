# Adaptation du code Colab pour un script Python utilisable dans VSCode

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import joblib
import plotly.express as px

from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.decomposition import PCA
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score, calinski_harabasz_score, davies_bouldin_score

# === Chargement du dataset ===
df = pd.read_csv("df_clean.csv")  # place le fichier dans le même dossier que ce script
print(df.head())

# === Prétraitement ===
cols_to_keep = ['LAT', 'LON', 'SOG', 'COG', 'Heading', 'VesselType']
df_selected = df[cols_to_keep]

num_features = ['SOG', 'COG', 'Heading']
cat_features = ['VesselType']

preprocessor = ColumnTransformer([
    ('num', StandardScaler(), num_features),
    ('cat', OneHotEncoder(), cat_features)
])

X = df_selected[num_features + cat_features]
X_transformed = preprocessor.fit_transform(X)

# === PCA pour visualisation ===
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_transformed)

plt.scatter(X_pca[:, 0], X_pca[:, 1], s=3)
plt.title("Projection PCA des données navires")
plt.xlabel("PC1")
plt.ylabel("PC2")
plt.show()

# === K-Means - Détermination du nombre optimal de clusters ===
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

inertia = []
cluster_range = range(2, 10)
for k in cluster_range:
    model = KMeans(n_clusters=k, random_state=42)
    model.fit(X_scaled)
    inertia.append(model.inertia_)

plt.plot(cluster_range, inertia, marker='o')
plt.xlabel("Nombre de clusters (k)")
plt.ylabel("Inertia")
plt.title("Méthode du coude pour K-Means")
plt.show()

# === Clustering final ===
kmeans = KMeans(n_clusters=5, random_state=42, n_init='auto')
labels = kmeans.fit_predict(X_scaled)
df_selected['Cluster'] = labels

print("Silhouette Score:", silhouette_score(X_scaled, labels))
print("Calinski-Harabasz Index:", calinski_harabasz_score(X_scaled, labels))
print("Davies-Bouldin Index:", davies_bouldin_score(X_scaled, labels))

# === Sauvegarde du modèle ===
joblib.dump(kmeans, "model.pkl")
joblib.dump(preprocessor, "preprocessor.pkl")

# === Carte des clusters ===
fig = px.scatter_mapbox(df_selected,
                        lat="LAT",
                        lon="LON",
                        color="Cluster",
                        hover_data=["VesselType", "SOG", "COG"],
                        zoom=3,
                        height=600)

fig.update_layout(mapbox_style="open-street-map")
fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
fig.show()

# === Prédiction interactive ===
def predict_cluster_interactif():
    print("\U0001F4E1 Prédiction de cluster pour un navire\n")

    try:
        lat = float(input("LAT (latitude) : "))
        lon = float(input("LON (longitude) : "))
        sog = float(input("SOG (Speed Over Ground) : "))
        cog = float(input("COG (Course Over Ground) : "))
    except ValueError:
        print("\u274C Entrée invalide : les valeurs numériques doivent être valides.")
        return

    navire = {
        "LAT": lat,
        "LON": lon,
        "SOG": sog,
        "COG": cog
    }

    df_input = pd.DataFrame([navire])
    model = joblib.load("model.pkl")

    try:
        X_input = df_input[['LAT', 'LON', 'SOG', 'COG']]
        cluster = model.predict(X_input)[0]
        print(f"\n✅ Ce navire appartient au cluster : {cluster}")
    except Exception as e:
        print(f"\u274C Erreur pendant la prédiction : {e}")

# Appel manuel
# predict_cluster_interactif()