README - Prédiction de Trajectoires de Navires
==============================================

Objectif :
Ce programme charge un modèle Random Forest entraîné pour prédire la position
future d’un navire (latitude et longitude) à un horizon de 5, 10 ou 15 minutes,
à partir de données AIS.

Fichiers nécessaires :
Assurez-vous d’avoir dans le même dossier que le script :
- script_client3.py            ← votre script principal
- model_rf_5min.joblib         ← modèle sauvegardé pour horizon 5 min
- model_rf_10min.joblib        ← modèle sauvegardé pour horizon 10 min
- model_rf_15min.joblib        ← modèle sauvegardé pour horizon 15 min
- test_data_5min.joblib        ← données de test associées
- test_data_10min.joblib
- test_data_15min.joblib

Prérequis :
Python 3 installé, ainsi que les bibliothèques suivantes grace a la ligne ci-dessous:

pip install -r requirements.txt

Ouvrez un terminal dans le dossier contenant les fichiers par exemple:

/Users/nolanjauffrit/Desktop/annee_3/projet_IA

et éxécutez la commande suivante:
python3 script_client_3_final.py (pour mac)
ou 
python script_client3.py 
