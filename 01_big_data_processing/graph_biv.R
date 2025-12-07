
df_clean$Area <- df_clean$Length * df_clean$Width
df_clean$VesselTypeGroup <- as.numeric(as.character(df_clean$VesselTypeGroup))

df_clean$VesselDescription <- factor(df_clean$Status,
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
                                     ))

status_order <- c(
  "En route (moteur) [0]",
  "En route (voile) [8]",
  "En pêche [7]",
  "Non manœuvrable [2]",
  "Manœuvre restreinte [3]",
  "Contraint par tirant d’eau [4]",
  "Au mouillage [1]",
  "Amarré [5]",
  "Échoué [6]",
  "Balise SAR AIS [14]",
  "Non défini [15]",
  "Réservé (futur) [9]",
  "Réservé (futur) [10]",
  "Réservé (futur) [11]",
  "Réservé (futur) [12]",
  "Réservé (futur) [13]"
)
df_clean$StatusLabel <- factor(df_clean$StatusLabel, levels = status_order)
levels(df_clean$Status_ordered)

# Re-mapper les Status dans un ordre logique (les chiffres restent, mais ordonnés différemment)
status_ordered <- c(0, 8, 7, 2, 3, 4, 1, 5, 6, 14, 15, 9, 10, 11, 12, 13)

# Créer une version ordonnée dans une nouvelle variable, si besoin
df_clean$Status_ordered <- match(df_clean$Status, status_ordered) - 1

# Corrélation SOG vs VesselType

ggplot(df_clean, aes(x = VesselGroupLabel, y = SOG)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  labs(
    title = "vitesse en fonction du type de bateau",
    x = "type de bateau",
    y = "Vitesse (SOG en nœuds)"
  ) +
  theme_minimal(base_size = 15)

# Corrélation Area vs Vessel type

ggplot(df_clean, aes(x = VesselGroupLabel, y = Area)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  labs(
    title = "Aire du navire en fonction du type de bateau",
    x = "Type de navire ",
    y = "Aire des navires (en m^2)"
  ) +
  theme_minimal(base_size = 15)

# Corrélation Sog vs status

ggplot(df_clean, aes(x = Status_ordered, y = SOG)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  labs(
    title = "vitesse du navire en fonction du status du navire",
    x = "Status du navire ",
    y = "Vitesse du navire (en noeuds)"
  ) +
  theme_minimal(base_size = 15)


# Corrélation vesseltype vs draft

ggplot(df_clean, aes(x = VesselGroupLabel, y = Draft)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  labs(
    title = "Tirant d'eau du navire en fonction du type de bateau",
    x = "Type de navire ",
    y = "Tirant d'eau du navire"
  ) +
  theme_minimal(base_size = 15)

# Corrélation aire vs vitesse
r <- cor(df_clean$Area, df_clean$SOG, use = "complete.obs")
ggplot(df_clean, aes(x = Area, y = SOG)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "darkblue", size = 1.2, linetype = "dashed") +
  annotate("text", x = max(df_clean$Area, na.rm = TRUE) * 0.6, 
           y = max(df_clean$SOG, na.rm = TRUE) * 0.9,
           label = paste0("coeff de corrélation = ", round(r, 2)),
           size = 5, color = "black") +
  labs(
    title = "Vitesse du navire en fonction de son aire",
    x = "Aire des navires (en m^2)",
    y = "Vitesse (SOG en nœuds)"
  ) +
  theme_minimal(base_size = 15)

# Corrélation vesseltype vs status

ggplot(df_clean, aes(x = VesselGroupLabel, y = Status_ordered)) +
  geom_point(color = "skyblue", alpha = 0.6, size = 2) +
  labs(
    title = "status du navire en fonction de son type",
    x = "Type de navire",
    y = "Status des navires"
  ) +
  theme_minimal(base_size = 15)
summary(df_clean)


library(dplyr)
library(corrplot)
library(reshape2)

# Garder uniquement les variables utiles
df_clean$Area <- df_clean$Length * df_clean$Width
df_numeric <- df_clean[, c("Draft", "SOG", "Length", "Width", "Area")] # 3. Calcul de la matrice de corrélation
cor_matrix <- cor(df_numeric, use = "complete.obs", method = "pearson")

# Visualisation de la matrice 
corrplot(cor_matrix,
         method = "color",
         type = "upper",
         tl.col = "black",
         tl.srt = 45,
         addCoef.col = "black",
         number.cex = 0.7)


variables <- c("SOG", "Draft", "Length", "Width", "Area")

# ANOVA pour chaque variable
for (var in variables) {
  cat("\n--- ANOVA pour", var, "---\n")
  model <- aov(as.formula(paste(var, "~ VesselGroupLabel")), data = df_clean)
  print(summary(model))
  
  # Créer le graphique et le stocker dans un objet
  p <- ggplot(df_clean, aes(x = VesselGroupLabel, y = .data[[var]])) +
    geom_boxplot(fill = "skyblue") +
    labs(title = paste("Distribution de", var, "par type de navire"),
         x = "Type de navire", y = var) +
    theme_minimal()
  
  # Afficher le graphique
  print(p)
  
  # Sauvegarder le graphique
  ggsave(filename = paste0(var, "_by_VesselGroupLabel.png"), plot = p, width = 8, height = 5)
}

