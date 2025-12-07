# Structure du code suivant :
#
#  28–31  | Chargement des bibliothèques
#  34–37  | Chargement du fichier CSV
#  40–41  | Copie du jeu de données original et calcul de l'Area
#  44–77  | Nettoyage des données (valeurs aberrantes, filtres géographiques, valeurs manquantes)
#  80–83  | Suppression des doublons (MMSI uniques) et NA
#  88–108 | Création de StatusLabel (statut lisible)
# 111–123 | Regroupement des VesselType par tranche (60,70,80) => création de VesselGroupLabel
# 122–125 | Filtrage des SOG > 0 et création df_model
# 128–141 | Séparation en données d'entraînement/test (70/30)
# 144–150 | Régression logistique multinomiale via `nnet::multinom`
# 151-156 | Prédictions sur les données de test et matrice de confusion
# 157–160 | Calcul de la précision globale
# 162–198 | Calcul des métriques : prévalence, sensibilité, etc.
# 205-213 | Visualisation de la matrice de confusion (ggplot)
# 215–229 | Estimation de la vitesse par type prédit (moyenne)
# 230–246 | Calculs d’erreurs (MAE, RMSE)
# 249–254 | Boxplot de la vitesse réelle par type prédit
# 258-264  | Histogramme de la distribution de l’erreur relative







library(ggplot2)
library(dplyr)
library(scales)  # pour étiquettes en pourcentages
library(nnet)


##### CHARGEMENT FICHIER
df = read.csv('C:/Users/Nolan/OneDrive/Documents/big_data/projet/vessel-total-clean.csv',
              na.strings=c("\\N", "", "NA")) # convertir ces chaînes en NA


##### COPIE DES DONNEES (garder l'originale intact)

df_clean <- df
df_clean$Area <- df_clean$Length * df_clean$Width

#####NETTOYAGE

# Nettoyage de la colonne TransceiverClass : suppression points-virgules.
df_clean$TransceiverClass <- gsub(";", "", df_clean$TransceiverClass)  # enlever les ';'

# Convertir Draft en numérique dans df_clean
df_clean$Draft <- as.numeric(df_clean$Draft)

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
# Supprimer les Class A avec Draft hors plage [0.5, 28.5] et DRAFT et IMO NA 
#Objectif: garder les valeurs des classes B valides car ils n'ont pas obligation de renseigner leurs drafts et IMO
df_clean <- df_clean[!(df_clean$TransceiverClass == "A" & (is.na(df_clean$Draft) | df_clean$Draft < 0.5 | df_clean$Draft > 28.5)), ]
df_clean <- df_clean[!(df_clean$TransceiverClass == "A" & is.na(df_clean$IMO)), ]

#suppression des statuts inutiles et des incohérence dans les status
df_clean <- df_clean %>%
  filter(!(Status==0 & SOG==0)) %>%
  filter(!(Status==5 & SOG>0)) %>%
  filter(!Status==8) %>%
  filter(!Status==15)

# Vérifier les valeurs manquantes
data_unique_MMSI <- df_clean[!duplicated(df_clean$MMSI),]
colSums(is.na(df_clean))



#définition des différents status
df_clean$StatusLabel <- factor(df_clean$Status,
                               levels = 0:15,
                               labels = c(
                                 "En route (moteur) [0]",            
                                 "Au mouillage [1]",                 
                                 "Non manœuvrable [2]",           
                                 "Manœuvre restreinte [3]",       
                                 "Contraint par tirant d’eau [4]",
                                 "Amarré [5]",                    
                                 "Échoué [6]",                      
                                 "En pêche [7]",                    
                                 "En route (voile) [8]",            
                                 "Réservé (futur) [9]",             
                                 "Réservé (futur) [10]",            
                                 "Réservé (futur) [11]",            
                                 "Réservé (futur) [12]",            
                                 "Réservé (futur) [13]",            
                                 "Balise SAR AIS [14]",             
                                 "Non défini [15]"                  
                               )
)


###Groupement des vesseltype par dizaines pour simplifications visuelles

df_clean$VesselTypeGroup <- floor(df_clean$VesselType / 10) * 10
df_clean$VesselTypeGroup <- factor(df_clean$VesselTypeGroup, ordered = TRUE)

df_clean$VesselGroupLabel <- factor(df_clean$VesselTypeGroup,
                                    levels = c(60,70,80),
                                    labels = c(
                                      "Navires de passagers",
                                      "Cargo",
                                      "Pétroliers"
                                    )
)

df_clean<-df_clean%>%
  filter(SOG>0)

df_model <- df_clean


##séparation en données entrainements et données test
set.seed(123)  # pour reproductibilité
n <- nrow(df_model)
train_indices <- sample(seq_len(n), size = 0.7 * n)
train_data <- df_model[train_indices, ]
test_data <- df_model[-train_indices, ]

# Reconvertir proprement les colonnes catégorielles
train_data$TransceiverClass <- as.factor(train_data$TransceiverClass)
train_data$VesselGroupLabel <- as.factor(train_data$VesselGroupLabel)

# Nettoyer les niveaux non utilisés (sécurité)
train_data$TransceiverClass <- droplevels(train_data$TransceiverClass)
train_data$VesselGroupLabel <- droplevels(train_data$VesselGroupLabel)


#Création du modèle de régression logistique multinomiale

# Multinomial logistic regression
model <- multinom(VesselGroupLabel ~ Length + Width + Area + Draft + Cargo ,
                  data = train_data)

##évaluation du model !
# Prédiction
predictions <- predict(model, newdata = test_data)

# Matrice de confusion
conf_mat <- table(Predicted = predictions, Actual = test_data$VesselGroupLabel)
print(conf_mat)

# Taux de précision global
accuracy <- sum(diag(conf_mat)) / sum(conf_mat)
cat("Précision globale :", round(accuracy * 100, 2), "%\n")

# Initialisation des différents calculs de la matrice de confusion !
classes <- levels(test_data$VesselGroupLabel)
results <- data.frame(Classe = character(),
                      Prevalence = numeric(),
                      Sensibilite = numeric(),
                      Specificite = numeric(),
                      Precision = numeric(),
                      Exactitude = numeric(),
                      stringsAsFactors = FALSE)

for (classe in classes) {
  # Valeurs pour chaque classe binaire (1-vs-rest)
  TP <- conf_mat[classe, classe]
  FN <- sum(conf_mat[, classe]) - TP
  FP <- sum(conf_mat[classe, ]) - TP
  TN <- sum(conf_mat) - TP - FN - FP
  
  # Calculs
  prevalence <- (TP + FN) / (TP + FN + FP + TN)
  sensibilite <- ifelse((TP + FN) == 0, NA, TP / (TP + FN))
  specificite <- ifelse((TN + FP) == 0, NA, TN / (TN + FP))
  precision   <- ifelse((TP + FP) == 0, NA, TP / (TP + FP))
  exactitude  <- (TP + TN) / (TP + TN + FP + FN)
  
  # Stockage
  results <- rbind(results, data.frame(
    Classe = classe,
    Prevalence = round(prevalence, 3),
    Sensibilite = round(sensibilite, 3),
    Specificite = round(specificite, 3),
    Precision = round(precision, 3),
    Exactitude = round(exactitude, 3)
  ))
}

print(results)


#Visualisation des résultats au cas ou

conf_df <- as.data.frame(conf_mat)
ggplot(conf_df, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), color = "black") +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(title = "Matrice de confusion",
       x = "Réel", y = "Prédit") +
  theme_minimal()


# Calculer la vitesse moyenne par groupe dans les données d'entraînement
vitesse_moyenne_par_groupe <- train_data %>%
  group_by(VesselGroupLabel) %>%
  summarise(vitesse_moyenne = mean(SOG, na.rm = TRUE))

# Associer la vitesse moyenne estimée à chaque prédiction dans test_data
test_data$Vitesse_predite <- vitesse_moyenne_par_groupe$vitesse_moyenne[
  match(predictions, vitesse_moyenne_par_groupe$VesselGroupLabel)]

# Vitesse réelle
test_data$Vitesse_reelle <- test_data$SOG

# Calculer l'erreur absolue
test_data$Erreur_absolue <- abs(test_data$Vitesse_reelle - test_data$Vitesse_predite)

# Calculer l'erreur moyenne absolue (MAE)
MAE <- mean(test_data$Erreur_absolue, na.rm = TRUE)
cat("Erreur moyenne absolue (MAE) de la vitesse prédite :", round(MAE, 3), "nœuds\n")

# Optionnel : Erreur quadratique moyenne (RMSE)
RMSE <- sqrt(mean((test_data$Vitesse_reelle - test_data$Vitesse_predite)^2, na.rm = TRUE))
cat("Erreur quadratique moyenne (RMSE) de la vitesse prédite :", round(RMSE, 3), "nœuds\n")

# Supprimer les cas où la vitesse réelle est très faible (< 1 nœud par exemple)
test_data_filtré <- test_data %>% filter(Vitesse_reelle >= 1)
# Erreur relative en %
test_data_filtré$Erreur_relative_pct <- 100 * abs(test_data_filtré$Vitesse_reelle - test_data_filtré$Vitesse_predite) / test_data_filtré$Vitesse_reelle

# Moyenne de l'erreur relative
MAE_pct <- mean(test_data_filtré$Erreur_relative_pct, na.rm = TRUE)
cat("Erreur moyenne relative (MAE%) corrigée :", round(MAE_pct, 2), "%\n")

test_data$Vessel_pred <- predict(model, newdata = test_data)

ggplot(test_data, aes(x = Vessel_pred, y = SOG)) +
  geom_boxplot(fill = "steelblue", alpha = 0.6) +
  labs(title = "Distribution des vitesses selon le type prédit",
       x = "Type de navire prédit", y = "Vitesse réelle (SOG)") +
  theme_minimal()




ggplot(test_data_filtré, aes(x = Erreur_relative_pct)) +
  geom_histogram(binwidth = 10, fill = "darkred", color = "white", alpha = 0.7) +
  labs(title = "Distribution de l'erreur relative (%)",
       x = "Erreur relative (%)",
       y = "Nombre de données") +
  theme_minimal()
