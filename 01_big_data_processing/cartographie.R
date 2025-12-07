#installations des librairies nécessaires

#application du filtre

#afficher les stats descriptives d'un bateau par son MMSI

#importation d'un fond de carte centré sur le Golfe du Mexique

#affichage de la trajectoire d'un seul bateau par son MMSI sous forme de graphique

#zones des routes principales sous forme de graphique

#affichage de la trajectoire d'un seul bateau par son MMSI sur la carte

#affichage de la trajectoire de 5 bateaux par leur MMSI sur la carte

#affichage de la trajectoire colorée de 5 bateaux par leur MMSI sur la carte

#affichage des routes principales sous forme de zones de chaleur pour les 5 bateaux sélectionnés

#affichage des routes principales pour tous les bateaux confondus

#affiche des principaux ports du Golfe

#affichage du nom de quelques ports avec celui le plus fréquenté

#prédiction de la variable VesselType en fonction des variables pertinentes

#sélection de quelques bateaux, calculer leur vitesse et mesurer quantitativement l’erreur commise par la méthode


#installation des librairies nécessaires
install.packages(c("tidyverse", "lubridate", "skimr", "ggplot2"))
library(tidyverse)
library(lubridate)
library(skimr)
install.packages(c("dplyr", "ggplot2", "sf"))
library(dplyr)
library(ggplot2)
install.packages(c("leaflet", "dplyr"))
library(leaflet)
library(dplyr)
library(RColorBrewer)
install.packages("leaflet.extras")
library(leaflet.extras)  # Nécessaire pour heatmap
install.packages("caret")
install.packages("randomForest")
install.packages("geosphere")
install.packages("Metrics")
library(geosphere)
library(Metrics)
library(caret)
library(randomForest)


df = read.csv("C:/Users/celia/OneDrive/Bureau/Année 3 ISEN Brest/Big Data/Projet S6/vessel-total-clean.csv", 
              na.strings=c("\\N","","NA")).


#application du filtre
# Copier le jeu de données
df_clean <- df
# Nettoyage de la colonne TransceiverClass : suppression points-virgules.
df_clean$TransceiverClass <- gsub(";", "", df_clean$TransceiverClass)  # enlever les ';'

# Convertir Draft en numérique dans df_clean
df_clean$Draft <- as.numeric(df_clean$Draft)  # très important !

# Supprimer les vitesses irréalistes
df_clean <- df_clean[df_clean$SOG >= 0 & df_clean$SOG <= 50, ]

# Limiter les positions valides
df_clean <- df_clean[df_clean$LAT >= 18 & df_clean$LAT <= 31, ]
df_clean <- df_clean[df_clean$LON >= -97 & df_clean$LON <= -78, ]

# COG entre 0 et 359.9
df_clean <- df_clean[df_clean$COG >= 0 & df_clean$COG <= 359.9, ]

# Supprimer les NA sur Length, Width
df_clean <- df_clean[!is.na(df_clean$Length) & !is.na(df_clean$Width), ]

# Supprimer Length aberrants (<2 m ou >400 m)
df_clean <- df_clean[df_clean$Length >= 2 & df_clean$Length <= 400, ]

# Supprimer Width aberrants (<1 m ou >70 m)
df_clean <- df_clean[df_clean$Width >= 1 & df_clean$Width <= 70, ]

table(df_clean$TransceiverClass)
# Supprimer les Class A avec Draft hors plage [0.5, 28.5]
df_clean <- df_clean[!(
  df_clean$TransceiverClass == "A" & 
    (is.na(df_clean$Draft) | df_clean$Draft < 0.5 | df_clean$Draft > 28.5)
), ]
df_clean <- df_clean[!(df_clean$TransceiverClass == "A" & is.na(df_clean$IMO)), ]

# Vérifier les classes restantes
table(df_clean$TransceiverClass)
table(df_clean$TransceiverClass, is.na(df_clean$Draft))

# Vérifier les valeurs manquantes
colSums(is.na(df_clean))
nrow(df_clean)


#fonction pour afficher les stats descriptives d’un bateau par son MMSI
stats_bateau <- function(df_clean) {
  # Lister les MMSI uniques
  mmsi_dispo <- unique(df_clean$MMSI)
  print("Bateaux disponibles (MMSI) :")
  print(head(mmsi_dispo, 200000))  # Affiche les 200000 premiers MMSI dispo
  
  # Demander à l'utilisateur d'en saisir un
  mmsi_choisi <- as.numeric(readline(prompt = "Entrez le MMSI du bateau : "))
  
  # Filtrer le bateau
  df_bateau <- df_clean %>% filter(MMSI == mmsi_choisi)
  
  if (nrow(df_bateau) == 0) {
    cat("Aucune donnée trouvée pour ce MMSI.\n")
  } else {
    cat("Statistiques descriptives pour le bateau MMSI :", mmsi_choisi, "\n")
    print(
      df_bateau %>%
        select(where(is.numeric)) %>%
        summarise_all(list(
          mean = ~mean(., na.rm = TRUE),
          sd = ~sd(., na.rm = TRUE),
          min = ~min(., na.rm = TRUE),
          max = ~max(., na.rm = TRUE),
          median = ~median(., na.rm = TRUE)
        ))
    )
  }
}
stats_bateau(df)

df_clean %>% arrange(MMSI, BaseDateTime) #données triées par date


#importation d'un fond de carte centré sur le Golfe du Mexique
leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%  # fond de carte propre
  setView(lng = -89, lat = 25, zoom = 5)    # centre sur le Golfe du Mexique


#afficher la trajectoire d’un seul bateau par son nom (MMSI)
trajet_bateau <- function(df_clean, nom_bateau) {
  df_bateau <- df_clean %>% 
    filter(MMSI == nom_bateau) %>%
    arrange(BaseDateTime)
  
  ggplot(df_bateau, aes(x = LON, y = LAT)) +
    geom_path(color = "blue") +  #trace des lignes connectées dans l’ordre des données
    theme_minimal() +
    labs(title = paste("Trajectoire du bateau :", 636017833),
         x = "Longitude", y = "Latitude")
}
trajet_bateau(df_clean, 636017833)


#zones des routes principales sous forme de graphique
ggplot(df_clean, aes(x = LON, y = LAT)) + #aes : C’est l’endroit où je dis à ggplot ce que chaque variable représente visuellement : les axes, les couleurs, les tailles, etc.
  stat_bin2d(bins = 100) +  #carte de densité en 2D, Découpe la surface (LON/LAT) en carrés (grille), Compte le nombre de points dans chaque carré, Affiche une carte de chaleur (plus un carré est rempli, plus il est coloré)
  scale_fill_viridis_c() +  #C’est une palette de couleurs perceptuellement correcte, lisible même en noir & blanc, bon contraste, compatible daltoniens.
  coord_fixed() +  #fixe le rapport de proportions X/Y, Sans ça, les cartes sont souvent écrasées ou étirées, cela garantit que 1 unité sur l’axe X = 1 unité sur l’axe Y (ex. : 1° de latitude = 1° de longitude visuellement).
  theme_minimal() +  #thème visuel épuré, supprime les grilles, arrière-plan gris, contours inutiles, rend le graphique sobre et plus lisible.
  labs(title = "Zones de passage fréquentes (routes principales)",
       x = "Longitude", y = "Latitude")


#affichage de la trajectoire d'un seul bateau par son MMSI sur la carte
df_bateau <- df_clean %>% 
  filter(MMSI == 636017833 ) %>%
  arrange(BaseDateTime)

leaflet(data = df_bateau) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolylines(
    lng = ~LON,
    lat = ~LAT,
    color = "blue",
    weight = 2,
    opacity = 0.8
  ) %>%
  setView(lng = -89, lat = 25, zoom = 5)


#affichage de la trajectoire de 5 bateaux par leur MMSI sur la carte
bateaux <- df_clean %>% 
  filter(!is.na(MMSI)) %>%  #Garde les lignes avec un identifiant MMSI non manquant
  distinct(MMSI) %>%  #Garde 1 ligne unique par MMSI (évite les doublons)
  slice_sample(n = 5) %>%  #Tire au hasard 5 MMSI (bateaux)
  pull(MMSI)  #Récupère la colonne MMSI comme vecteur

# Filtrer les trajets
df_sample <- df_clean %>% filter(MMSI %in% bateaux) %>% arrange(MMSI, BaseDateTime) # Garde les lignes correspondant aux 5 MMSI sélectionnés, Trie par MMSI puis par temps croissant et %in% permet de tester l'appartenance à un vecteur (MMSI fait partie de bateaux)

# Affichage de la carte avec plusieurs polylines
map <- leaflet() %>%  #initialise une carte vide
  addProviderTiles("CartoDB.Positron") %>%  # Ajoute un fond de carte clair
  setView(lng = -89, lat = 25, zoom = 5)  # Centre la carte sur le Golfe du Mexique

for (mmsi in bateaux) {  #boucle sur chaque bateau.
  traj <- df_sample %>% filter(MMSI == mmsi)  #extrait les positions du bateau courant.
  map <- map %>%
    addPolylines(data = traj, lng = ~LON, lat = ~LAT, color = ~"red", weight = 2)  #trace une ligne reliant les points (trajet du bateau) sur la carte.
}
map  #Affiche la carte complète avec les 5 trajectoires.


#affichage de la trajectoire colorée de 5 bateaux par leur MMSI sur la carte
# Choisir quelques MMSI aléatoires
bateaux <- df_clean %>% 
  filter(!is.na(MMSI)) %>%
  distinct(MMSI) %>%
  slice_sample(n = 5) %>%
  pull(MMSI)

# Filtrer les trajectoires
df_sample <- df_clean %>%
  filter(MMSI %in% bateaux) %>%
  arrange(MMSI, BaseDateTime)

# Générer une palette de couleurs (1 par bateau)
palette <- colorFactor(palette = brewer.pal(length(bateaux), "Set1"), domain = bateaux)

# Initialiser la carte
map <- leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  setView(lng = -89, lat = 25, zoom = 5)

# Ajouter les trajectoires colorées
for (mmsi in bateaux) {
  traj <- df_sample %>% filter(MMSI == mmsi)
  map <- map %>%
    addPolylines(  # fils colorés qui tracent des mouvements
      data = traj,
      lng = ~LON, lat = ~LAT,
      color = palette(mmsi),   # Couleur unique par bateau
      weight = 2,
      label = paste("MMSI:", mmsi)
    )
}
map


#affichage des routes principales sous forme de zones de chaleur pour les 5 bateaux sélectionnés
leaflet(df_sample) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addHeatmap(lng = ~LON, lat = ~LAT, blur = 15, radius = 8, max = 0.0001) %>%  # addHeatmap : permet d'afficher une carte de chaleur, blur : Adoucit les transitions entre les zones, radius : Rayon autour de chaque point (densité locale), max : Intensité max de la chaleur (0 à 1)
  setView(lng = -89, lat = 25, zoom = 5)


#affichage des routes principales pour tous les bateaux confondus
leaflet(df_clean) %>%  #%>% : et ensuite passe le résultat à ... (chaîne d'instructions)
  addProviderTiles("CartoDB.Positron") %>%
  addHeatmap(
    lng = ~LON, lat = ~LAT,
    radius = 8,       # Rayon autour des points
    blur = 15,        # Flou pour adoucir la densité
    max = 0.05        # Densité max pour la palette de couleurs
  ) %>%
  setView(lng = -89, lat = 25, zoom = 5)


#affichage des principaux ports du Golfe
icon_port <- makeIcon(
  iconUrl = "https://cdn-icons-png.flaticon.com/512/684/684908.png",  # URL du logo
  iconWidth = 25, iconHeight = 25      # Taille du logo (pixels)
)

# Étape 1 : extraire les zones avec Status = 5 (par ex : "moored")
ports <- df_clean %>%
  filter(Status == 5) %>%
  select(LAT, LON) %>%
  distinct() %>%       # Évite les doublons
  na.omit()            # Supprime les valeurs manquantes

# Étape 2 : affichage avec les ports présumés
leaflet(df_clean) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addHeatmap(lng = ~LON, lat = ~LAT, radius = 8, blur = 15, max = 0.05) %>%
  addMarkers(data = ports, lng = ~LON, lat = ~LAT,
             icon = icon_port,
             label = ~paste("Port présumé")) %>%
  setView(lng = -89, lat = 25, zoom = 5)


#affichage du nom des ports avec celui le plus fréquenté
# 1. Liste des ports
ports <- data.frame(
  Nom = c("Port of Houston", "Port of New Orleans", "Port of Galveston",
          "Port Tampa Bay", "Port of Mobile", "Port of Corpus Christi",
          "Port of Pascagoula", "Port of Freeport", "Port Manatee",
          "Port of Lake Charles", "Port Panama City"),
  LAT = c(29.736, 29.954, 29.306, 27.944, 30.690, 27.817,
          30.354, 28.944, 27.637, 30.226, 30.148),
  LON = c(-95.267, -90.063, -94.793, -82.446, -88.039, -97.395,
          -88.556, -95.358, -82.567, -93.217, -85.678)
)

# 2. Extraire les positions de navires à quai
df_ports <- df_clean %>%
  filter(Status == 5, !is.na(LAT), !is.na(LON))

# 3. Pour chaque port, compter le nombre de navires dans un rayon de 10 km
ports$nb_points <- sapply(1:nrow(ports), function(i) {
  sum(distHaversine(
    matrix(c(ports$LON[i], ports$LAT[i]), ncol = 2),
    matrix(c(df_ports$LON, df_ports$LAT), ncol = 2)
  ) < 10000)  # rayon de 10 km
})

# 4. Identifier le port avec le plus de points
top_port <- ports$Nom[which.max(ports$nb_points)]

# 5. Attribuer les couleurs
ports$color <- ifelse(ports$Nom == top_port, "red", "blue")

# 6. Afficher la carte avec couleurs dynamiques en fonction du nombre de données
leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addCircleMarkers(data = ports, lng = ~LON, lat = ~LAT,
                   color = ~color,
                   radius = 6,
                   label = ~paste(Nom, "-", nb_points, "données"),
                   fillOpacity = 0.8) %>%
  setView(lng = -89, lat = 27.5, zoom = 5)


#prédiction de la variable VesselType en fonction des variables pertinentes.
# 1. Nettoyage complet
# Filtrer et sélectionner les colonnes pertinentes
df_model <- df_clean %>%
  filter(!is.na(VesselType)) %>%
  select(VesselType, SOG, COG, Heading, Length, Width, Draft) %>%
  na.omit()

nrow(df_model)
table(df$VesselType)
# Transformer VesselType en facteur
df_model$VesselType <- as.factor(df_model$VesselType)

set.seed(123)
trainIndex <- createDataPartition(df_model$VesselType, p = 0.8, list = FALSE)
train <- df_model[trainIndex, ]
test  <- df_model[-trainIndex, ]

table(df_model$VesselType)       # ← distribution totale
table(df_model$VesselType[trainIndex])

model <- randomForest(VesselType ~ ., data = train)

pred <- predict(model, test)

cm_df <- as.data.frame(conf$table)

varImpPlot(model, main = "Importance des variables dans la prédiction de VesselType")


#sélection de quelques bateaux, calculer leur vitesse et mesurer quantitativement l’erreur commise par la méthode
bateaux <- df_clean %>%
  filter(!is.na(MMSI), !is.na(LAT), !is.na(LON), !is.na(BaseDateTime)) %>%
  group_by(MMSI) %>%
  filter(n() >= 10) %>%  # au moins 10 points
  distinct(MMSI) %>%
  slice_sample(n = 5) %>%
  pull(MMSI)

df_sample <- df_clean %>%
  filter(MMSI %in% bateaux) %>%
  arrange(MMSI, BaseDateTime)

# Fonction pour calculer les vitesses estimées
df_speed <- df_sample %>%
  arrange(MMSI, BaseDateTime) %>%
  group_by(MMSI) %>%
  mutate(
    LAT_prev = lag(LAT),
    LON_prev = lag(LON),
    time_prev = lag(BaseDateTime),
    dist_m = distHaversine(cbind(LON, LAT), cbind(LON_prev, LAT_prev)),  # distance en mètres
    time_diff = as.numeric(difftime(BaseDateTime, time_prev, units = "secs")),  # en secondes
    speed_calc = (dist_m / time_diff) * 1.94384  # vitesse en nœuds (1 m/s = 1.94384 knots)
  ) %>%
  filter(!is.na(speed_calc), !is.na(SOG))

df_speed_valid <- df_speed %>% filter(SOG > 0)

mae <- mae(df_speed_valid$SOG, df_speed_valid$speed_calc)
rmse_val <- rmse(df_speed_valid$SOG, df_speed_valid$speed_calc)
mape_val <- mape(df_speed_valid$SOG, df_speed_valid$speed_calc) * 100

cat("Erreur moyenne absolue (MAE) :", round(mae, 2), "nœuds\n")
cat("Erreur quadratique moyenne (RMSE) :", round(rmse_val, 2), "nœuds\n")
cat("Erreur relative moyenne (MAPE) :", round(mape_val, 2), "%\n")












