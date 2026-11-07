library(tidyverse)



## Diabetes_Cohort_Brumagne.R
## Capstone @data26 - Partie C : Statistiques et R
## Martin Brumagne

## C0 Importer et préparer les données ----
## C0.1 Importer et examiner les tables ----

patients_raw  <- read_csv("Patients.csv")
lifestyle_raw <- read_csv("Hygiene_vie.csv")
glucose_raw   <- read_csv("Historique_glycemique.csv")
consult_raw   <- read_csv("Consultations.csv")

str(patients_raw)
str(lifestyle_raw)
str(glucose_raw)
str(consult_raw)

summary(patients_raw)
summary(lifestyle_raw)

summary(glucose_raw)
summary(consult_raw)
table(is.na(patients_raw$Sexe))
table(is.na(patients_raw$`Corticoïdes`))

##- 1500 patients, 1500 lignes d'hygiène de vie, 11565 mesures, 3609 consultations
## - NA : Sexe 4 et Corticoïdes 6.
## - Valeurs impossibles repérées avec summary() :age max : 278 et 
## - 64 heures de sommeil dans lifestyle surement oubli d'une virgule


## C0.2 Appliquer les règles de nettoyage R1 à R5 ----
## Colonnes renommées comme dans la base SQL 

## Patients : R1 (sexe), R2 (corticoïdes), R3 (âge)

patients <- patients_raw %>%
  rename(
    patient_id      = `ID patient`,
    age             = `Âge (ans)`,
    sex             = Sexe,
    weight_kg       = `Poids (kg)`,
    height_cm       = `Taille (cm)`,
    blood_group     = `Groupe sanguin`,
    glucose_mg_dl   = `Glycémie (mg/dL)`,
    insulin_uiu_ml  = `Insuline (µUI/mL)`,
    corticosteroids = `Corticoïdes`
  ) %>%
  mutate(
    sex = case_when(
      str_to_lower(sex) %in% c("f", "femme")      ~ "F",
      str_to_lower(sex) %in% c("m", "h", "homme") ~ "M",
      TRUE                                         ~ "Unknown"
    ),
    corticosteroids = if_else(is.na(corticosteroids) | str_to_lower(corticosteroids) == "na",
                              "Non", corticosteroids),
    age = if_else(age > 110, NA_real_, age)
    )


## Hygiène de vie : R4 (niveau d'activité)

lifestyle <- lifestyle_raw %>%
  rename(
    patient_id             = `ID patient`,
    stress_score           = `Stress (0-10)`,
    stress_level           = `Niveau de stress`,
    sleep_h                = `Sommeil (h/nuit)`,
    activity_min_week      = `Activité physique (min/sem)`,
    activity_level         = `Niveau d'activité`,
    fruit_veg_per_day      = `Fruits et légumes (portions/jour)`,
    sugary_drinks_per_week = `Boissons sucrées (portions/sem)`,
    fast_food_per_week     = `Fast-food (repas/sem)`,
    diet_score             = `Score alimentation (0-10)`,
    diet_quality           = `Qualité de l'alimentation`,
    smoker                 = Tabagisme,
    alcohol_units_week     = `Alcool (unités/sem)`
  ) %>%
  mutate(activity_level = if_else(activity_level == "faible", "Faible", activity_level))

## Historique glycémique 
glucose_history <- glucose_raw %>%
  rename(
    patient_id     = `ID patient`,
    measure_date   = `Date de mesure`,
    glucose_mg_dl  = `Glycémie (mg/dL)`,
    weight_kg      = `Poids (kg)`,
    blood_pressure = `Tension artérielle (mmHg)`,
    hba1c_pct      = `HbA1c (%)`
  )


## Consultations : R5 (doublons)

consultations <- consult_raw %>%
  rename(
    patient_id   = `ID patient`,
    consult_date = Date,
    consult_type = `Type de consultation`,
    provider     = `Médecin/service`,
    reason       = Motif
  ) %>%
  distinct()

## Vérifications

table(patients$sex)
table(patients$corticosteroids)
summary(patients$age)
table(lifestyle$activity_level)
nrow(patients)
nrow(consultations)

## Résultats : F 929, M 566, Unknown 5 ; Non 1372, Oui 128 ;
## âge max 85, moyenne 50,75, 1 NA (P144) ; activité Faible 313 ;
## 1500 patients et 3608 consultations (1 doublon supprimé).
## Mêmes résultats qu'en SQL et en Power BI.

## C0.3 Fusionner Patients et Hygiène de vie, puis nettoyer ----

cohort <- patients %>%
  left_join(lifestyle, by = "patient_id")

## Vérification de la fusion

nrow(cohort)
which(is.na(cohort$smoker))
summary(cohort)

## Nettoyage complémentaire : sommeil impossible (> 24 h par nuit) -> NA

cohort %>% filter(sleep_h > 24)
cohort <- cohort %>%
  mutate(sleep_h = if_else(sleep_h > 24, NA, sleep_h))
summary(cohort$sleep_h)

## Observations :
## - P079 : 64 h de sommeil par nuit, impossible (probablement 6,4 mal saisi).
##   Mis à NA, comme l'âge en R3 : on ne devine pas la vraie valeur.
## 1 NA en age

## C0.4 Calculer l'IMC et examiner sa distribution ----

cohort <- cohort %>%
  mutate(bmi = weight_kg / (height_cm / 100)^2)

summary(cohort$bmi)

## Histogramme de l'IMC
cohort %>%
  ggplot(aes(x = bmi)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "black") +
  ggtitle("Distribution de l'IMC") +
  xlab("IMC (kg/m²)") +
  ylab("Nombre de patients") +
  theme(plot.title = element_text(hjust = 0.5))

## Observations :
## - IMC de 16,5 à 39,6 kg/m², sans valeur impossible.
## - Moyenne 25,35 et médiane 25,25, très proches : distribution presque
##   symétrique, en forme de cloche, centrée autour de 25


## C1 Décrire la cohorte ----

## C1.1 Effectif, âge moyen et médian, glycémie moyenne ----

cohort %>%
  summarise(
    n_patients   = n(),
    age_moyen    = round(mean(age, na.rm = TRUE), 2),
    age_median   = median(age, na.rm = TRUE),
    glycemie_moy = round(mean(glucose_mg_dl), 1)
  )

## C1.2 Distribution de la glycémie et catégories ----

summary(cohort$glucose_mg_dl)


## Catégories de glycémie
cohort <- cohort %>%
  mutate(
    glucose_category = case_when(
      glucose_mg_dl < 100 ~ "Normale",
      glucose_mg_dl < 126 ~ "Altérée",
      TRUE                ~ "Plage diabétique"
    ),
    glucose_category = factor(glucose_category,
                              levels = c("Normale", "Altérée", "Plage diabétique"))
  )
table(cohort$glucose_category)
round(prop.table(table(cohort$glucose_category)) * 100, 1)

## Histogramme de la glycémie, coloré par catégorie
cohort %>%
  ggplot(aes(x = glucose_mg_dl, fill = glucose_category)) +
  geom_histogram(binwidth = 5, color = "black") +
  ggtitle("Distribution de la glycémie de référence") +
  xlab("Glycémie (mg/dL)") +
  ylab("Nombre de patients") +
  theme(plot.title = element_text(hjust = 0.5))


## Observations :
## - Glycémie de 62 à 200,9 mg/dL ; médiane 91,5 < moyenne 93,4 : distribution
##   asymétrique, avec une longue queue vers la droite (40 patients > 150 mg/dL).
## - Normale 1104 (73,6 %), altérée 346 (23,1 %), plage diabétique 50 (3,3 %) :
##   mêmes effectifs qu'en SQL (Q4.2) et en Power BI.


## C1.3 Glycémie selon le tabagisme et la qualité de l'alimentation ----

cohort <- cohort %>%
  mutate(diet_quality = factor(diet_quality,
                               levels = c("Peu équilibrée", "Moyennement équilibrée",
                                          "Équilibrée")))

## Tableau par statut tabagique
cohort %>%
  group_by(smoker) %>%
  summarise(
    n_patients   = n(),
    glycemie_moy = round(mean(glucose_mg_dl), 1),
    glycemie_med = median(glucose_mg_dl)
  )

## Tableau par qualité de l'alimentation
cohort %>%
  group_by(diet_quality) %>%
  summarise(
    n_patients   = n(),
    glycemie_moy = round(mean(glucose_mg_dl), 1),
    glycemie_med = median(glucose_mg_dl)
  )
## Boxplot par statut tabagique
cohort %>%
  ggplot(aes(x = smoker, y = glucose_mg_dl)) +
  geom_boxplot(fill = "lightgreen", alpha = 0.7, varwidth = TRUE) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
  ggtitle("Glycémie selon le statut tabagique") +
  xlab("Fumeur") +
  ylab("Glycémie (mg/dL)") +
  theme(plot.title = element_text(hjust = 0.5))

## Boxplot par qualité de l'alimentation
cohort %>%
  ggplot(aes(x = diet_quality, y = glucose_mg_dl)) +
  geom_boxplot(fill = "lightgreen", alpha = 0.7, varwidth = TRUE) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
  ggtitle("Glycémie selon la qualité de l'alimentation") +
  xlab("Qualité de l'alimentation") +
  ylab("Glycémie (mg/dL)") +
  theme(plot.title = element_text(hjust = 0.5))


## Observations :
## - Tabac : glycémie moyenne quasi identique (93,9 chez les fumeurs, 93,3 chez
##   les non-fumeurs) : pas de tendance visible.
## - Alimentation : gradient régulier, la glycémie baisse quand l'alimentation
##   s'améliore (95,2 -> 92,0 -> 88,6 mg/dL, soit -6,6 entre peu équilibrée et
##   équilibrée). Le groupe "Peu équilibrée" contient plus de valeurs extrêmes.



##install.packages("car") 

## C2 Tabagisme et glycémie ----
library(car)

## C2.2 Vérifier les conditions d'application du test t ----

cohort <- cohort %>%
  mutate(smoker = factor(smoker))

## Normalité de la glycémie dans chaque groupe (Shapiro-Wilk)
by(cohort$glucose_mg_dl, cohort$smoker, shapiro.test)

## Homogénéité des variances (Levene)
leveneTest(glucose_mg_dl ~ smoker, data = cohort)

## Vérification visuelle : distribution de la glycémie dans chaque groupe
cohort %>%
  ggplot(aes(x = glucose_mg_dl)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "black") +
  facet_wrap(~ smoker) +
  ggtitle("Glycémie selon le statut tabagique") +
  xlab("Glycémie (mg/dL)") +
  ylab("Nombre de patients") +
  theme(plot.title = element_text(hjust = 0.5))

## Observations :
## - Normalité rejetée dans les deux groupes (p < 0,001) : asymétrie à droite (C1.2).
##   Grands effectifs (1211 et 289) : le test t reste fiable malgré la non-normalité.
## - Levene : p = 0,20, variances comparables. Test de Welch gardé par prudence
##   (groupes de tailles très inégales).
## - Indépendance : chaque patient appartient à un seul groupe.
## -> Test retenu : test t de Welch.

## C2.3 Test t de Welch ----
## H0 : même glycémie moyenne chez les fumeurs et les non-fumeurs
## H1 : glycémies moyennes différentes 

t.test(glucose_mg_dl ~ smoker, data = cohort, var.equal = FALSE, conf.level = 0.95)

## Observations :
## - Moyennes : Non 93,29 / Oui 93,92 mg/dL -> différence (Non - Oui) = -0,63 mg/dL
## - IC95 [-2,63 ; 1,37] contient 0 et p = 0,54 -> on ne rejette pas H0
## - Écart très faible, sans importance clinique
## -> Pas de différence de glycémie moyenne entre fumeurs et non-fumeurs

## C3 Qualité de l'alimentation et glycémie ----

## C3.1 Variables, statistiques descriptives et graphique ----
## Réponse : glucose_mg_dl (quantitative) ; groupe : diet_quality (3 groupes indépendants)
## diet_quality est déjà un facteur avec ses 3 niveaux dans l'ordre (C1.3)

cohort %>%
  group_by(diet_quality) %>%
  summarise(n = n(),
            moyenne = round(mean(glucose_mg_dl), 1),
            ecart_type = round(sd(glucose_mg_dl), 1),
            mediane = median(glucose_mg_dl))

cohort %>%
  ggplot(aes(x = glucose_mg_dl)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "black") +
  facet_wrap(~ diet_quality) +
  ggtitle("Glycémie selon la qualité de l'alimentation") +
  xlab("Glycémie (mg/dL)") +
  ylab("Nombre de patients") +
  theme(plot.title = element_text(hjust = 0.5))

## C3.2 Choix de la méthode et conditions d'application ----
## 3 groupes indépendants, réponse quantitative -> ANOVA à un facteur
## Normalité vérifiée sur les résidus du modèle
modele_c3 <- aov(glucose_mg_dl ~ diet_quality, data = cohort)
shapiro.test(residuals(modele_c3))

## Homogénéité des variances (Levene)
leveneTest(glucose_mg_dl ~ diet_quality, data = cohort)

## - Résidus non normaux (p < 0,001) ; grands effectifs, comme en C2
## - Levene : p = 0,005 -> variances différentes (écart-type 19,9 contre ~14, cf. C3.1)
## - Groupes très déséquilibrés (755 / 665 / 80)
## -> méthode retenue :ANOVA  grands effectifs (80 à 755 par groupe), comme en C2 ;
##    écarts-types du même ordre (13,7 à 19,9) -> interpréter avec prudence

## C3.3 ANOVA à un facteur ----
## H0 : même glycémie moyenne dans les 3 groupes
## H1 : au moins une moyenne diffère

summary(modele_c3)


## C3.4 ----
TukeyHSD(modele_c3)

## Catégories de glycémie (C1.2) selon la qualité de l'alimentation
table(cohort$diet_quality, cohort$glucose_category)
round(prop.table(table(cohort$diet_quality, cohort$glucose_category), 1) * 100, 1)
  

## Observations :
## - ANOVA : p < 0,001 -> au moins une moyenne diffère
## - Tukey : glycémie plus élevée dans Peu équilibrée que dans les 2 autres groupes
##   (-3,2 et -6,6 mg/dL) ; pas de différence entre Moyennement et Équilibrée (p = 0,23)
## - Écarts de quelques mg/dL, moyennes toutes < 100 mg/dL
## - Plage diabétique : 4,9 % (Peu) / 2,0 % (Moyennement) / 0 % (Équilibrée)


## C4.1 Première et dernière mesure de chaque patient ----

dates_patient <- glucose_history %>%
  group_by(patient_id) %>%
  summarise(date_initiale = min(measure_date),
            date_finale = max(measure_date))
## Patients ayant des mesures à au moins 2 dates distinctes
dates_patient <- dates_patient %>%
  filter(date_initiale != date_finale)
nrow(dates_patient)


## Première et dernière observation datée de chaque patient
premiere_derniere <- glucose_history %>%
  left_join(dates_patient, by = "patient_id") %>%
  filter(measure_date == date_initiale | measure_date == date_finale)
nrow(premiere_derniere)

## Observations :
## - Les 1 500 patients ont au moins 2 dates distinctes -> tous conservés


## C4.2 Delta glycémique et représentation graphique ----
## Moment de chaque mesure : initiale ou finale
premiere_derniere <- premiere_derniere %>%
  mutate(moment = if_else(measure_date == date_initiale, "initiale", "finale"))


## Une ligne par patient

evolution <- premiere_derniere %>%
  group_by(patient_id, moment) %>%
  summarise(glycemie = mean(glucose_mg_dl)) %>%
  pivot_wider(names_from = moment, values_from = glycemie)

## Delta glycémique : glycémie finale - glycémie initiale
evolution <- evolution %>%
  mutate(delta = finale - initiale)
nrow(evolution)
summary(evolution$delta)


evolution %>%
  ggplot(aes(x = delta)) +
  geom_histogram(binwidth = 2, fill = "steelblue", color = "black") +
  ggtitle("Évolution de la glycémie (finale - initiale)") +
  xlab("Delta glycémique (mg/dL)") +
  ylab("Nombre de patients") +
  theme(plot.title = element_text(hjust = 0.5))


## Observations :
## - 1 500 patients, une ligne chacun
## - Delta centré sur 0 (moyenne -0,53 ; médiane -0,45 mg/dL), de -37,2 à +39,9
## - Distribution symétrique : des hausses et des baisses, pas de tendance nette

## C4.3 Comparaison de la glycémie initiale et finale ----
## Données appariées (même patient) : normalité des différences
shapiro.test(evolution$delta)


## - Shapiro : p = 0,077 -> normalité des différences non rejetée -> test t apparié


## H0 : la glycémie moyenne ne change pas entre la première et la dernière mesure
## H1 : elle change (test bilatéral)
t.test(evolution$finale, evolution$initiale, paired = TRUE)

## Observations :
## - Différence moyenne (finale - initiale) = -0,53 mg/dL, IC95 [-1,11 ; 0,06], p = 0,078
## - IC contient 0 -> on ne rejette pas H0 : glycémie moyenne stable dans le temps


## C5 Modélisation de la glycémie ----

## C5.1 Choix du modèle ----
## Glycémie = variable quantitative continue, expliquée par plusieurs variables
## (quantitatives : âge, IMC, activité ; qualitatives : tabagisme, alimentation)
## -> régression linéaire multiple 


## C5.2 Jeu de données pour la modélisation ----
donnees_c5 <- cohort %>%
  select(glucose_mg_dl, age, bmi, smoker, activity_min_week, diet_quality)
summary(donnees_c5)

## Retrait des lignes avec une valeur manquante
donnees_c5 <- na.omit(donnees_c5)
nrow(donnees_c5)

## - Seule valeur manquante : l'âge de P144 (âge impossible mis en NA en C0.2)

## C5.3 Ajustement du modèle ----
modele_c5 <- lm(glucose_mg_dl ~ age + bmi + smoker + activity_min_week + diet_quality,
                data = donnees_c5)
summary(modele_c5)
confint(modele_c5, level = 0.95)

## - Âge : +0,33 mg/dL par an (p < 0,001) ; IMC : +0,62 mg/dL par kg/m² (p < 0,001)
## - Activité : -0,01 mg/dL par min/sem (p = 0,038), soit -1 mg/dL pour 100 min/sem
## - Alimentation (réf. Peu équilibrée) : Moyennement -1,8 (p = 0,034) ; Équilibrée -6,3 (p < 0,001)
## - Tabagisme : non significatif (p = 0,40)

##install.packages("forestmodel")
## Forest plot des coefficients
library(forestmodel)
forest_model(modele_c5)

## C5.4 Conditions d'application ----
## Graphiques diagnostiques
par(mfrow = c(2, 2))
plot(modele_c5)
par(mfrow = c(1, 1))


## Multicolinéarité : corrélations entre les variables quantitatives
cor.test(donnees_c5$age, donnees_c5$bmi, method = "pearson")
cor.test(donnees_c5$age, donnees_c5$activity_min_week, method = "pearson")
cor.test(donnees_c5$bmi, donnees_c5$activity_min_week, method = "pearson")


## C5.5 Qualité globale du modèle ----
summary(modele_c5)

## Observations :
## - F = 46,17 ; p < 0,001 -> modèle globalement significatif
## - R² ajusté = 0,153 -> le modèle explique 15 % de la variabilité de la glycémie
## - Erreur standard résiduelle = 16 mg/dL


## C5.6 Comparaison avec le modèle sans la qualité de l'alimentation ----
modele_c5_reduit <- lm(glucose_mg_dl ~ age + bmi + smoker + activity_min_week,
                       data = donnees_c5)
anova(modele_c5_reduit, modele_c5)

## Observations :
## - F = 6,65 ; p = 0,001 -> l'alimentation améliore significativement le modèle
## -> modèle complet conservé

##install.packages(c("pROC", "factoextra"))

## C6 Modélisation des anomalies glycémiques ----


## C6.1 Variable réponse binaire ----
cohort <- cohort %>%
  mutate(statut_glycemique = if_else(glucose_mg_dl >= 126, "Glycémie élevée", "Glycémie normale"))


cohort <- cohort %>%
  mutate(statut_glycemique = factor(statut_glycemique,
                                    levels = c("Glycémie normale", "Glycémie élevée")))
table(cohort$statut_glycemique)

## Observations :
## - 1 450 glycémies normales et 50 élevées (3,3 %, comme la plage diabétique en C1.2)

## C6.2 Choix du modèle ----
## Réponse binaire (Glycémie élevée / normale) -> régression logistique binaire## C6.2 Choix du modèle ----


donnees_c6 <- cohort %>%
  select(statut_glycemique, age, bmi, smoker)
donnees_c6 <- na.omit(donnees_c6)
nrow(donnees_c6)
table(donnees_c6$statut_glycemique)


## C6.3 Ajustement du modèle ----
modele_c6 <- glm(statut_glycemique ~ age + bmi + smoker, data = donnees_c6, family = binomial)
summary(modele_c6)


## Odds ratios et leurs IC95
exp(coef(modele_c6))
exp(confint(modele_c6))

## Comparaison avec le modèle nul
modele_c6_nul <- glm(statut_glycemique ~ 1, data = donnees_c6, family = binomial)
anova(modele_c6_nul, modele_c6, test = "Chisq")


## Observations :
## - Modèle globalement significatif (p < 0,001)
## - Âge : OR = 1,10 par an (p < 0,001) ; IMC : OR = 1,09 par kg/m² (p = 0,012)
## - Tabagisme : OR = 0,55, IC95 contient 1 (p = 0,22) 

## C6.4 Qualité de discrimination ----
## Probabilité prédite de glycémie élevée pour chaque patient
prob_c6 <- predict(modele_c6, type = "response")

## Courbe ROC et AUC
roc_c6 <- pROC::roc(response = donnees_c6$statut_glycemique, predictor = prob_c6)
roc_c6
plot(roc_c6, print.auc = TRUE)

## Observations :
## - AUC = 0,85 : bonne discrimination entre glycémies élevées et normales

## C7 Exploration multivariée des données ----

## C7.1 Variables, valeurs manquantes et échelles de mesure ----
donnees_c7 <- cohort %>%
  select(age, bmi, glucose_mg_dl, insulin_uiu_ml, activity_min_week, sleep_h, diet_score)
summary(donnees_c7)

## Retrait des valeurs manquantes 
donnees_c7 <- na.omit(donnees_c7)
nrow(donnees_c7)



## C7.2 Analyse en composantes principales (ACP) ----
## Variables quantitatives à résumer -> ACP sur variables centrées-réduites
acp <- prcomp(donnees_c7, center = TRUE, scale. = TRUE)
summary(acp)

## Observations :
## - PC1 : 27,3 % de la variance ; PC2 : 17,2 % ; PC1 + PC2 = 44,5 %


## C7.3 Importance des dimensions et contributions des variables ----
library(factoextra)

## Part de variance expliquée par chaque composante (scree plot)
fviz_eig(acp)


## Cercle des corrélations
fviz_pca_var(acp)

## C7.4 Représentation des patients sur PC1 et PC2 ----
fviz_pca_ind(acp, geom = "point")
## Observations :
## - Un grand nuage centré, sans groupes séparés pour la plupart des patients
## - Un petit groupe isolé en bas à droite, dans la direction de la glycémie et de l'âge :
##   patients à glycémie très élevée (groupe 150-200 mg/dL vu en C1.2)

