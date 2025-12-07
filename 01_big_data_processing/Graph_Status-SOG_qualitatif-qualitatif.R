#############################################
# SCRIPT D’ANALYSE CHI2 : Statut vs Vitesse (SOG)
# Objectif : Explorer la relation entre le statut de navigation
#            et la vitesse du navire (catégorisée), via un test du Chi²
#
# Structure du code :
#   30-31   | Chargement du fichier CSV
#   37      | Calcul d’une nouvelle variable "aire"
#   41-81   | Nettoyage des données
#   82–106  | Création des libellés explicites pour les statuts (`StatusLabel`)
#  111-121  | Création d'une variable regroupée `VesselGroupLabel` (passager/cargo/pétrolier)
#  143-144  | Suppression du statut 2 (non manœuvrable)
#  145–154  | Filtrage du tableau pour Chi²
#  155–156  | Application du test du Chi²
#  158-165  | Affichage du Mosaicplot (relation entre vitesse et statut)
#  169-198  | Création du tableau croisé pour ggplot et calculs des pourcentages par statut
#  200-218  | Génération du barplot (ggplot) avec % empilés
#############################################





library(ggplot2)
library(dplyr)
library(scales)  # pour étiquettes en pourcentages


##### CHARGEMENT FICHIER
df = read.csv('C:/Users/Nolan/OneDrive/Documents/big_data/projet/vessel-total-clean.csv',
              na.strings=c("\\N", "", "NA")) # convertir ces chaînes en NA


##### COPIE DES DONNEES (garder l'originale intact)

df_clean <- df
df_clean$Area <- df_clean$Length * df_clean$Width

#####NETTOYAGE

# Nettoyage de la colonne TransceiverClass : suppression points-virgules. (au cas ou car problème sur 1 ordi)
df_clean$TransceiverClass <- gsub(";", "", df_clean$TransceiverClass)  # enlever les ';' gsub: global substitution

# Convertir Draft en numérique dans df_clean (au cas ou car problème sur 1 ordi)
df_clean$Draft <- as.numeric(df_clean$Draft)

# Supprimer les vitesses irréalistes
df_clean <- df_clean[df_clean$SOG >= 0 & df_clean$SOG <= 50, ]

# Limiter les positions valides
df_clean <- df_clean[df_clean$LAT >= 18 & df_clean$LAT <= 31, ]
df_clean <- df_clean[df_clean$LON >= -97 & df_clean$LON <= -78, ]

# COG entre 0 et 359.9 (0=360)
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

#nb de bateaux
data_unique_MMSI <- df_clean[!duplicated(df_clean$MMSI),]

# Vérifier les valeurs manquantes
colSums(is.na(df_clean))

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



table(df_clean$Status, df_clean$SOG == 0)



##### TESTS Chi2 et GRAPHES correspondant

### TEST Chi2  Statut/SOG

#création des catégories de vitesse 
df_clean$SOG_cat <- cut(df_clean$SOG, 
                        breaks=c(-Inf, 1, 5, 15, 30, Inf), 
                        labels=c("Immobilisé", "Lente", "Modérée", "Rapide", "Très rapide"))


##Traçage graphe Statut/vitesse en pourcentage
#définition des différents status

#tableau croisé status/SOG
df_clean<- df_clean%>%
  filter(!Status==2)
table_ns_sog <- table(df_clean$Status, df_clean$SOG_cat)


# Refaire le tableau croisé avec les labels lisibles
table_status_label_sog <- table(df_clean$StatusLabel, df_clean$SOG_cat)

# Supprimer toutes les lignes et colonnes qui ne contiennent que des zéros
table_filtered <- table_status_label_sog[rowSums(table_status_label_sog) > 0,
                                         colSums(table_status_label_sog) > 0]

test_chi=chisq.test(table_filtered)
test_chi$expected
# Mosaic plot avec labels propres
mosaicplot(table_filtered ,
           color = TRUE,
           main = "Mosaic plot : Statut de navigation vs Catégorie de vitesse (SOG)",
           xlab = "Statut de navigation",
           ylab = "Catégorie de vitesse",
           las = 2,  # orientation verticale des labels
           cex.axis = 0.6)  # taille des labels plus petite pour lisibilité


## Création du tableau croisé : Status (X) vs SOG_cat. 
#Il compte la fréquence de chaque catégories de vitesse en fonction de leurs statuts
df_plot_status_SOG <- as.data.frame(table(df_clean$StatusLabel, df_clean$SOG_cat))
colnames(df_plot_status_SOG) <- c("Status", "SOG_cat", "Freq") #nommer les colonnes


df_plot_filtered_status_SOG <- df_plot_status_SOG %>%
  filter(Freq > 0) %>%           # On garde seulement les cases non nulles
  group_by(Status) %>%           #permet de faire les opérations suivantes pour chaque type de statut
  mutate(pct = Freq / sum(Freq)) %>% #mutate permet d'ajouter une colonne 'pct' qui est le résultat de la fréquence/somme totale du groupe
  ungroup() 

# Somme des fréquences par statut
statut_sums <- df_plot_filtered_status_SOG %>%
  group_by(Status) %>%
  #On veut un tableau résumé où chaque Status est listé une fois avec le total associé
  summarise(total = sum(Freq)) #on réduit le nb de ligne à 1/groupe et crée une colonne total qui est la somme des fréquence par statut

# Garder les statuts avec au moins 1 bateau
statuts_valides <- statut_sums %>%
  filter(total > 0) %>%
  pull(Status)

# Filtrer le tableau complet sur ces statuts
df_plot_filtered_status_SOG <- df_plot_filtered_status_SOG %>%
  filter(Status %in% statuts_valides)

# Calculer les pourcentages pour chaque statut
df_plot_pct_status_SOG <- df_plot_status_SOG %>%
  group_by(Status) %>% #permet de faire les opérations suivantes pour chaque type de statut
  mutate(pct = Freq / sum(Freq))  # permet d'ajouter une colonne 'pct' qui est le résultat de la fréquence/somme totale du groupe

### Graphe avec pourcentages dans les boxes
graph_status_SOG = ggplot(df_plot_filtered_status_SOG, aes(x = Status, y = pct, fill = SOG_cat)) +      
  #aes: esthetique du plot. X catégorie statut de bateau, Y hauteur des barres(%), fill : couleur des barres dépend de la catégorie de vitesse 
  geom_bar(stat = "identity", color = "white", linewidth = 0.3) +   
  #"identity" indique que la hauteur des barres correspond directement a la variable y; color et linewidth de la bordure
  geom_text(aes(label = ifelse(pct > 0.03, paste0(round(pct * 100), "%"), "")),
            #aes(label = ifelse(.)) : affiche le pourcentage arrondi si > 3% et rien sinon
            position = position_stack(vjust = 0.5),#centrage vertical
            color = "white", size = 3.5) + #couleur et taille de texte
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +  #formatage de l'axe en pourcentage arrondi a l'entier
  
  labs(title = "Répartition des vitesses par statut de navigation",
       x = "Statut de navigation", y = "Pourcentage",
       fill = "Catégorie de vitesse (SOG)") +
  
  theme_minimal(base_size = 12) +  #applique un theme épuré
  theme(axis.text.x = element_text(angle = 45, hjust = 1), #modification de l'étiquette
        legend.position = "bottom")

graph_status_SOG

