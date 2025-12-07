# 🚢 Système Prédictif de Trajectoires AIS

> **Projet d'Ingénierie Complète :** De la conception (MCD, Architecture) à la réalisation (Big Data, IA, Web).

Ce projet vise à prédire les trajectoires de navires en utilisant des données AIS historiques. Il démontre une maîtrise du cycle de vie logiciel : conception rigoureuse, traitement de données massives, modélisation IA et visualisation.

---

### Conception & Architecture
Le système a été modélisé pour garantir sa robustesse avant le développement.

* **Architecture Technique :** Modèle Client-Serveur séparant le traitement (Back) de la visualisation (Front).
    * [Voir le schéma Client-Serveur (PDF)](/03_web_visualization/Client-Serveur%20PDF.pdf)
* **Modélisation de Données :** Conception d'une base relationnelle (MCD).
    * [Voir le Modèle Conceptuel de Données (PDF)](/03_web_visualization/MCD.pdf)
* **Gestion de Projet :** Suivi rigoureux des délais.
    * [Voir le Diagramme de Gantt (PDF)](/03_web_visualization/Copie%20de%20Diagramme%20de%20Gantt%20Projet%20Web.pdf)

---

### Structure du Code

#### 1. Big Data & Nettoyage (`/01_big_data_processing`)
* Scripts R/Python pour le nettoyage des biais statistiques et le filtrage des données GPS aberrantes.
* [Voir le Rapport d'Analyse Big Data](/01_big_data_processing/Rapport_Analyse_BigData.pdf)

#### 2. Intelligence Artificielle (`/02_ai_models`)
* Comparaison de modèles (Random Forest, SVM) pour la prédiction de position.
* [Voir le Rapport Final IA](/02_ai_models/Rapport%20final%20IA.pdf)

#### 3. Visualisation Web (`/03_web_visualization`)
* Interface cartographique respectant une charte graphique précise.
* [Voir la Charte Graphique (PDF)](/03_web_visualization/Charte%20Graphique.pdf)

---

### Stack Technique
* **Conception :** UML, Gantt, Merise (MCD)
* **Data & IA :** Python (Scikit-Learn, Pandas), R
* **Web :** HTML5, CSS3, JavaScript (Leaflet), PHP

---
*Développé par Nolan Nedelec.*
