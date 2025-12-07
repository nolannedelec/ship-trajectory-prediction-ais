#############################################
# SCRIPT D’ANALYSE BIVARIÉE : 
# Étude du lien entre le statut de navigation 
# et le type de navire avec test du Chi².
#
# Structure :
#   24-25   | Chargement du fichier CSV
#   29-30   | Copie du dataframe et calcul de la surface (Area)
#   35-75   | Nettoyage des données (vitesses, positions, Draft, IMO, etc.)
#   79-100  | Création de StatusLabel (statuts lisibles)
#  104-114  | Regroupement des types de navires (VesselTypeGroup -> VesselGroupLabel)
#  188-119  | Suppression du statut 2 (non manœuvrable) pour éviter un effectif trop faible
#  122-133  | Création de la table croisée : Status vs Type
#  139-140  | Test du Chi² entre statut et type
#  143-151  | Affichage du mosaicplot
#  155-165  | Transformation de la table croisée en data frame et calcul des pourcentages par statut
#  166-180  | Graphique ggplot : barres empilées colorées par type
#############################################





library(ggplot2)
library(dplyr)


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

df_clean <- df_clean %>%
  filter(!(Status==0 & SOG==0)) %>%
  filter(!(Status==5 & SOG>0)) %>%
  filter(!Status==8) %>%
  filter(!Status==15)



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



df_clean <- df_clean%>%
  filter(!Status==2) 
## Création du tableau croisé : Status (X) vs Vesseltype 
# Supprimer les lignes avec NA dans les deux variables utilisées
df_chi <- df_clean %>%
  filter(!is.na(StatusLabel), !is.na(VesselGroupLabel))

# Créer la table croisée
table_status_vessel <- table(df_chi$StatusLabel, df_chi$VesselGroupLabel)

# Filtrer la table pour ne garder que les lignes avec au moins un bateau
table_filtered <- table_status_vessel[rowSums(table_status_vessel) > 0, ]

# Supprimer aussi les colonnes où il n’y a aucun bateau (par précaution)
table_filtered <- table_filtered[, colSums(table_filtered) > 0]



# seulement pour les test chi2 car il n'y a pas assez de valeurs pour les utiliser

## TEST Chi2
test_chi=chisq.test(table_filtered)
test_chi

  
# Mosaicplot après le test Chi2
mosaicplot(table_filtered,
           main = "Mosaicplot : Statut de navigation vs Type de navire",
           xlab = "Statut de navigation",
           ylab = "Type de navire",
           color = TRUE,
           las = 2,  # texte vertical pour les étiquettes
           cex.axis = 0.7,  # taille texte étiquettes
           border = "grey50")


# Transformer la table croisée en data frame
df_plot_status_vessel <- as.data.frame(table(df_clean$StatusLabel, df_clean$VesselGroupLabel))
colnames(df_plot_status_vessel) <- c("Status", "VesselType", "Freq")


# Filtrer les lignes avec au moins 1 cas, et calculer les pourcentages
df_plot_filtered_status_vessel <- df_plot_status_vessel %>%
  filter(Freq > 0) %>%
  group_by(Status) %>%
  mutate(pct = Freq / sum(Freq)) %>%
  ungroup()

graph_status_vessel <- ggplot(df_plot_filtered_status_vessel, aes(x = Status, y = pct, fill = VesselType)) +
  geom_bar(stat = "identity", color = "white", linewidth = 0.3) +
  geom_text(aes(label = ifelse(pct > 0.03, paste0(round(pct * 100), "%"), "")),
            position = position_stack(vjust = 0.5),
            color = "white", size = 3.5) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "Répartition des types de navires par statut de navigation",
       x = "Statut de navigation", y = "Pourcentage",
       fill = "Type de navire") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

# Affichage
graph_status_vessel
