# 🚢 AIS Ship Trajectory Prediction System
> **Full Engineering Project:** From design (ERD, Architecture) to implementation (Big Data, AI, Web).

This project aims to predict ship trajectories using historical AIS data. It demonstrates mastery of the full software lifecycle: rigorous design, large-scale data processing, AI modeling, and visualization.

---

### Design & Architecture

Before writing the first line of code, the system was fully modeled to ensure its robustness.

* **Technical Architecture:** Client-Server model to separate data processing (Back-end) from visualization (Front-end).
    * [View the Architecture Diagram (PDF)](/04_docs/Client-Serveur%20PDF.pdf)
* **Data Modeling:** Design of a relational database (ERD) optimized for maritime time series.
    * [View the Entity-Relationship Diagram (PDF)](/04_docs/MCD.pdf)
* **Project Management:** Rigorous tracking of deadlines and milestones.
    * [View the Gantt Chart (PDF)](/04_docs/Diagramme%20de%20Gantt.pdf)

---

### Code Structure

#### 1. Big Data & Cleaning (`/01_big_data_processing`)
* R/Python scripts for removing statistical biases and filtering erroneous GPS data points.

#### 2. Artificial Intelligence (`/02_ai_models`)
* Comparison of models (Random Forest, SVM) for position prediction.
* Random Forest selected for its accuracy on noisy data.

#### 3. Web Visualization (`/03_web_visualization`)
* Map-based interface built according to a precise design system.
* [View the Design Guidelines (PDF)](/04_docs/Charte%20Graphique.pdf)

---

### Tech Stack

* **Design:** UML, Gantt, Merise (ERD)
* **Data & AI:** Python (Scikit-Learn, Pandas), R
* **Web:** HTML, CSS, JavaScript (Leaflet), PHP

---

*Developed by Nolan Nedelec, Nolan Jauffrit, and Célian Bosser as part of an operations research project.*
