Bonjour,



Pour lancer le script de prédiction, veuillez suivre les étapes suivantes :

Tout d'abord, assurez vous d'avoir installés les librairies nécessaires (pandas, joblib...)
Pour installer les dépendances :

pip install -r requirements.txt



Comment lancer le scipt ?

1. Ouvrez un terminal (ou l'invite de commandes sous Windows).
2. Placez-vous dans le dossier contenant ce script et les fichiers modèles ("preprocessor.joblib", "gridsearch_logistic.pkl").

3. Exécutez la commande suivante :

   python script_final_client_2.py

4. Le programme vous demandera d’entrer plusieurs valeurs :
   - Status AIS :un chiffre correspondant à l’état du navire (0: En route (moteur), 1: 'Au mouillage', 2: 'Non manoeuvrable', 3: 'Manoeuvre restreinte', 5: 'Amarré')
   - Longueur du navire (en mètres)
   - Largeur du navire (en mètres)
   - Tirant d'eau (en mètres)
   - Valeur Cargo (entre 60 et 89)

5. Le type de navire prédit s'affichera à la fin.




Bon courage !!
