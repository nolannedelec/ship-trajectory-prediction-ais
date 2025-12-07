df <- read.csv("/Users/nolanjauffrit/Desktop/annee_3/projet_big_data/vessel-total-clean.csv", na.strings = c("\\N", "", "NA"))

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

df_clean <- df_clean %>%
  filter(!(Status==0 & SOG==0)) %>%
  filter(!(Status==5 & SOG>0)) %>%
  filter(!Status==8) %>%
  filter(!Status==15)


# Vérifier les classes restantes
table(df_clean$TransceiverClass)
table(df_clean$TransceiverClass, is.na(df_clean$Draft))

# Vérifier les valeurs manquantes
colSums(is.na(df_clean))
library(dplyr)
library(ggplot2)

df_vit <- df[df$SOG >= 1, ]

df_plot <- df_clean %>%
  mutate(
    SOG_round = round(SOG),  # nom cohérent ici
    VesselTypeGroup = floor(VesselType / 10) * 10,
    VesselGroupLabel = factor(VesselTypeGroup,
                              levels = c(60, 70, 80),
                              labels = c("Navires de passagers", "Cargo", "Pétroliers"))
  ) %>%
  count(SOG_round, VesselGroupLabel) %>%
  arrange(-n)

# Graphique
ggplot(df_plot, aes(x = SOG_round, y = n, fill = VesselGroupLabel)) +
  geom_col(position = "identity", color = "black", alpha = 1) +
  scale_fill_brewer(palette = "Set2", name = "Type de navire") +
  labs(title = "Distribution des vitesses (SOG) selon le type de navire",
       x = "Vitesse (en nœuds, arrondie)",
       y = "Nombre de navires") +
  theme_minimal() +
  theme(legend.position = "right")



# Créer le jeu de données agrégé pour la longueur
df_plot_length <- df_clean %>%
  mutate(
    Length_round = round(Length),
    VesselTypeGroup = floor(VesselType / 10) * 10,
    VesselGroupLabel = factor(VesselTypeGroup,
                              levels = c(60, 70, 80),
                              labels = c("Navires de passagers", "Cargo", "Pétroliers"))
  ) %>%
  count(Length_round, VesselGroupLabel) %>%
  arrange(-n)

# Graphique
ggplot(df_plot_length, aes(x = Length_round, y = n, fill = VesselGroupLabel)) +
  geom_col(position = "identity", color = "black", alpha = 1) +
  scale_fill_brewer(palette = "Set2", name = "Type de navire") +
  labs(title = "Distribution des longueurs selon le type de navire après filtrage",
       x = "Longueur du navire (mètres, arrondie)",
       y = "Nombre de navires") +
  theme_minimal() +
  theme(legend.position = "right")

# Créer le jeu de données agrégé pour la draft
df_plot_draft <- df_clean %>%
  mutate(
    Draft_round = round(Draft),
    VesselTypeGroup = floor(VesselType / 10) * 10,
    VesselGroupLabel = factor(VesselTypeGroup,
                              levels = c(60, 70, 80),
                              labels = c("Navires de passagers", "Cargo", "Pétroliers"))
  ) %>%
  count(Draft_round, VesselGroupLabel) %>%
  arrange(-n)

# Graphique
ggplot(df_plot_draft, aes(x = Draft_round, y = n, fill = VesselGroupLabel)) +
  geom_col(position = "identity", color = "black", alpha = 1) +
  scale_fill_brewer(palette = "Set2", name = "Type de navire") +
  labs(title = "Distribution du tirant d'eau selon le type de navire après filtrage",
       x = "Tirant d'eau du navire (mètres)",
       y = "Nombre de navires") +
  ylim(0, max(df_VesselType$pct) + 5000) +
  theme_minimal() +
  theme(legend.position = "right")

# Créer le jeu de données agrégé pour la largeur
df_plot_width <- df_clean %>%
  mutate(
    Width_round = round(Width),
    VesselTypeGroup = floor(VesselType / 10) * 10,
    VesselGroupLabel = factor(VesselTypeGroup,
                              levels = c(60, 70, 80),
                              labels = c("Navires de passagers", "Cargo", "Pétroliers"))
  ) %>%
  count(Width_round, VesselGroupLabel) %>%
  arrange(-n)

# Graphique
ggplot(df_plot_width, aes(x = Width_round, y = n, fill = VesselGroupLabel)) +
  geom_col(position = "identity", color = "black", alpha = 1) +
  scale_fill_brewer(palette = "Set2", name = "Type de navire") +
  labs(title = "Distribution des largeurs selon le type de navire après filtrage",
       x = "Largeur du navire (mètres)",
       y = "Nombre de navires") +
  ylim(0, max(df_VesselType$pct) + 5000) +
  theme_minimal() +
  theme(legend.position = "right")

