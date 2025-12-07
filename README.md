# 🚢 Système Prédictif de Trajectoires AIS

> **Projet d'Ingénierie Complète :** De la conception (MCD, Architecture) à la réalisation (Big Data, IA, Web).

Ce projet vise à prédire les trajectoires de navires en utilisant des données AIS historiques. Il démontre une maîtrise du cycle de vie logiciel : conception rigoureuse, traitement de données massives, modélisation IA et visualisation.

---

### Conception & Architecture
Avant d'écrire la première ligne de code, le système a été entièrement modélisé pour garantir sa robustesse.

* **Architecture Technique :** Modèle Client-Serveur pour séparer le traitement de données (Back) de la visualisation (Front).
    * [Voir le schéma d'Architecture (PDF)](/04_docs/Client-Serveur%20PDF.pdf)
* **Modélisation de Données :** Conception d'une base relationnelle (MCD) optimisée pour les séries temporelles maritimes.
    * [Voir le Modèle Conceptuel de Données (PDF)](/04_docs/MCD.pdf)
* **Gestion de Projet :** Suivi rigoureux des délais et des jalons.
    * [Voir le Diagramme de Gantt (PDF)](/04_docs/Diagramme%20de%20Gantt.pdf)

---

### Structure du Code

#### 1. Big Data & Nettoyage (`/01_big_data_processing`)
* Scripts R/Python pour le nettoyage des biais statistiques et le filtrage des données GPS aberrantes.

#### 2. Intelligence Artificielle (`/02_ai_models`)
* Comparaison de modèles (Random Forest, SVM) pour la prédiction de position.
* Sélection du modèle Random Forest pour sa précision sur les données bruitées.

#### 3. Visualisation Web (`/03_web_visualization`)
* Interface cartographique respectant une charte graphique précise.
* [Voir la Charte Graphique (PDF)](/04_docs/Charte%20Graphique.pdf)

---

### Stack Technique
* **Conception :** UML, Gantt, Merise (MCD)
* **Data & IA :** Python (Scikit-Learn, Pandas), R
* **Web :** HTML, CSS, JavaScript (Leaflet), PHP

---
*Développé par Nolan Nedelec, Nolan Jauffrit et Célian Bosser dans le cadre d'un projet de recherche opérationnelle.*
