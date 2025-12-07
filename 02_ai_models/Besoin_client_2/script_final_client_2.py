import pandas as pd
import joblib

# Dictionnaire de correspondance StatusLabel pour faciliter l'entré des données dans le terminal
status_mapping = {
    0: 'En route (moteur)',
    1: 'Au mouillage',
    2: 'Non manoeuvrable',
    3: 'Manoeuvre restreinte',
    5: 'Amarré'
}
type_mapping = {
        60: 'Navire passager',
        70: 'Cargo',
        80: 'Petrolier'
}

def predict_vessel_type(status_label, length, width, draft, cargo):
    """
    Prédit le type de navire à partir des caractéristiques fournies.

    Paramètres :
    - status_label : str (valeurs autorisées : 0, 1, 2, 3, 5)
    - length : float
    - width : float
    - draft : float
    - cargo : float

    Retour :
    - str : Type de navire prédit ('Passenger', 'Cargo', 'Tanker')
    """
    # Charger le préprocesseur et le modèle optimisé
    preprocessor = joblib.load('preprocessor.joblib')
    grid_search = joblib.load('gridsearch_logistic.pkl')
    best_model = grid_search.best_estimator_

    # Préparer les données en DataFrame
    input_data = pd.DataFrame([{
        'StatusLabel': str(status_label),  # Important : transformer en string pour bien envoyer les données
        'Length': float(length),
        'Width': float(width),
        'Draft': float(draft),
        'Cargo': float(cargo)
    }])

    # Transformation des données d'entrée
    X_prepared = preprocessor.transform(input_data)

    # Prédiction
    prediction = best_model.predict(X_prepared)
    readable_prediction = type_mapping.get(prediction[0], 'Type inconnu')
    return readable_prediction  # Retourne la prédiction (classe du navire)


if __name__ == "__main__":
    # Interface console
    print("=== Prédiction du type de navire ===")
    try:
        status_label = str(input("Entrez Status AIS (0: En route (moteur), 1: 'Au mouillage', 2: 'Non manoeuvrable', 3: 'Manoeuvre restreinte', 5: 'Amarré') : "))
        length = float(input("Entrez la Longueur (5 à 300m) : "))
        width = float(input("Entrez la Largeur (3 à 60m) : "))
        draft = float(input("Entrez le Tirant d'eau (1 à 30m) : "))
        cargo = float(input("Entrez la Valeur Cargo (60 à 89) : "))

        # Appel de la fonction de prédiction
        result = predict_vessel_type(status_label, length, width, draft, cargo)
        print(f"\n>>> Type de navire prédit : {result}")

    except Exception as e:
        print("Erreur lors de la saisie ou de la prédiction :", e)