

--Q1.1 
select * from patients limit 10;
-- Il y a des majuscules et des minuscules dans la collonne "sex"

--Q1.2 
select patient_id, age , sex , glucose_mg_dl from patients
where age >80
order by age desc;
-- femme écrit en toutes lettres et age = 278, erreur de frappe surement.

--Q1.3 

-- Q1.3 
SELECT * FROM care_centres
WHERE region LIKE 'Wallonie%'
ORDER BY centre_name;

--Q1.4
-- Q1.4 Different blood groups, without repetition
SELECT DISTINCT blood_group FROM patients
ORDER BY blood_group;

-- distinct permet d'isoler les différentes valeurs, peut surement etre utilsié dans la collone sex pour trouver l'erreur plus facilemet
-- ici la réponse a l'air cohérente

--Q1.5 
select patient_id , age , glucose_mg_dl from patients
where glucose_mg_dl >= 126
order by glucose_mg_dl desc;
-- j'obtients 50 lignes et trois collonnes 
-- les patients avec la plus haute glycémie on l'air plus agé

--Q1.6
select * from treatments
where patient_id = 'P335'
order by start_date;
-- end date = null signifie que le patient 335 est encore sous metformine

--Q1.7 
select measure_date, glucose_mg_dl, weight_kg, hba1c_pct from glucose_history
where patient_id = 'P365'
order by measure_date asc;

-- l'historique montre 18 mesures dont plusieurs avant 2024
-- c'est donc surement un patient du centre c21

--Q1.8 

select * from patients 
where sex is null;

--Q2.1 

select count (*) from patients;
select count (*) from glucose_history;
select count (*) from consultations;

-- 1500 patients , 11565 mesures et 3609 consultations

--Q2.2

SELECT MIN(age) AS min_age,
       MAX(age) AS max_age,
       ROUND(AVG(age), 2)AS avg_age,
       ROUND(CAST(AVG(glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients;

-- ici du coup l'age max apparait encore improbable.
--celà fausse aussi la moyenne car celle ci est faussé par les valeurs extremes. 
-- la deuxième décimale de average_age est surement un 0 dont le fait que elle ne s'affiche pas
-- on pourrait surement faire le test avec 3 décimales et voir la valeur (50.898)
SELECT ROUND(AVG(age), 3) FROM patients;

-- Q2.3

select sex , count (*) from patients p 
group by sex ;
-- on obtient 12 valeurs diffénretes (11+null)
-- en additionnant je dirai 929 femmes , 566 hommes et 5 inconnus

--Q2.4 

select corticosteroids , count (*) from patients 
group by corticosteroids;
-- il ne devrait y avoir que oui ou non or ici 6 valeurs
-- on a donc 8 patients ici sans réponse 

--Q2.5 

select activity_level, count (*) from lifestyle 
group by activity_level;

-- ici il y a un faible qui n'est pas écrit "Faible" on a donc en fait réelement 313 faibles


--Q2.6

SELECT SUBSTR(CAST(measure_date AS TEXT), 1, 4) AS year,
       COUNT(*)AS n_measurements,
       COUNT(DISTINCT patient_id) AS n_patients
FROM   glucose_history
GROUP BY year
ORDER BY year;

-- Toujours le meme nombre de patients et de mesures pour 2020-2023
--les patients du centre C21

-- Q2.7 

SELECT drug_class,
COUNT(*)AS n_rows,
COUNT(DISTINCT patient_id) AS n_patients
FROM treatments
GROUP BY drug_class
ORDER BY n_rows DESC;

-- surement des personnes sur deux antidiabétiques ou des associations.



-- Q2.8a 
SELECT patient_id, consult_date, consult_type, provider, reason,
       COUNT(*) 
FROM consultations
GROUP BY patient_id, consult_date, consult_type, provider, reason
HAVING COUNT(*) > 1;

-- Q2.8b 
SELECT patient_id, relative, condition,
       COUNT(*) 
FROM family_history
GROUP BY patient_id, relative, condition
HAVING COUNT(*) > 1;

--Q2.9 
select patient_id, measure_date , count (*) from glucose_history
group by patient_id, measure_date 
having count(*) >1;

-- 2 patients ont deux mesures le meme jour

--Q2.10 

select glucose_mg_dl, count(*) from glucose_history 
group by glucose_mg_dl 
order by count (*)  desc 
limit 5 ; 

-- non elle n'est pas réaliste
-- c'est une valeur vraiment basse pour des diabétiques de types 2 
--celà peut résulter d'un problème de collecte 
-- il faut comprendre d'où vient cette erreur. 
--Cela est peut-etre du à une limite de l'apparaillage ou un appareil deffectueux

--Q3.1 

select sex, count (*) from patients p 
where lower (p.sex )in ('f','femme') 
group by sex ; 

update patients 
set sex = 'F'
where lower (sex) in ('f','femme');

SELECT sex, COUNT(*) AS n_patients
FROM patients
WHERE LOWER(sex) IN ('m', 'h', 'homme')
GROUP BY sex;

UPDATE patients
SET sex = 'M'
WHERE LOWER(sex) IN ('m', 'h', 'homme');

SELECT sex, COUNT(*) AS n_patients
FROM patients
WHERE sex is null or sex NOT IN ('F', 'M')
GROUP BY sex;

UPDATE patients
SET sex = 'Unknown'
WHERE sex IS NULL OR sex NOT IN ('F', 'M');

--Q3.2

SELECT patient_id, corticosteroids
FROM patients
WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS NULL;

SELECT corticosteroids, COUNT(*) AS n_patients
FROM patients
WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS NULL
GROUP BY corticosteroids;

UPDATE patients
SET corticosteroids = 'Non'
WHERE LOWER(corticosteroids) = 'na' OR corticosteroids IS NULL;

--Q3.3 

SELECT patient_id, age
FROM patients
WHERE age > 110;

update patients 
set age = null 
where age > 110 ;

SELECT MIN(age)AS min_age,
       MAX(age)AS max_age,
       ROUND(AVG(age), 2) AS avg_age
FROM patients;

-- la moyenne a bien bougé en modifiant la valeur extreme. 

--Q3.4

SELECT patient_id, activity_level
FROM lifestyle
WHERE activity_level = 'faible';

update lifestyle 
set activity_level = 'Faible'
where activity_level = 'faible';

--vérification : 

SELECT activity_level, COUNT(*) 
FROM lifestyle
GROUP BY activity_level
ORDER by activity_level  DESC;

--Q3.5 Apply R5 by creating two clean copies, then count their rows

CREATE TABLE consultations_clean  AS SELECT DISTINCT * FROM consultations;
CREATE TABLE family_history_clean AS SELECT DISTINCT * FROM family_history;

-- Vérification : on compte les lignes des nouvelles tables

SELECT COUNT(*) AS n_rows FROM consultations_clean;   
SELECT COUNT(*) AS n_rows FROM family_history_clean;

-- On observe que un doublon a été retiré dans consultations et 10 dans family_history

-- Part A4 - Analysis on clean data


-- Q4.1 :  For each sex, give the number of patients, their percentage (1 decimal) and their average age

SELECT sex,
       COUNT(*)AS n_patients,
       ROUND(100.0 * COUNT(*) / 1500, 1) AS pct_patients,
       ROUND(AVG(age), 1)AS avg_age
FROM patients
GROUP BY sex
ORDER BY n_patients DESC;

-- [X1] Clean in SQL : F = 929, M = 566, Unknown = 5
--      (Raw, Q2.3 : 12 valeurs différentes pour sex).
-- [X2] Âge moyen global après nettoyage : 50,75 (2 déc., Q3.3)
--      soit 50,7 à 1 décimale 
--      Raw (Q2.2) : 50,90, faussé par l'âge impossible de P144 (278 ans).



--Q4.2 :  Count the patients in each glucose category, with their average age. 

 SELECT CASE WHEN glucose_mg_dl < 100 THEN 'Normal'
            WHEN glucose_mg_dl < 126 THEN 'Impaired'
            ELSE 'Diabetes range'
       END AS glucose_category,
       COUNT(*) AS n_patients,
       ROUND(AVG(age), 1)  AS avg_age
FROM patients
GROUP BY glucose_category
ORDER BY MIN(glucose_mg_dl);


-- Observation : l'âge moyen augmente nettement avec la catégorie
---- (48 -> 56 -> 72 ans), ce qui confirme l'impression de la Q1.5.

--Les 50 patients "Diabetes range" sont les mêmes que les 50 de la Q1.5.


--Q4.3 : Count the consultations per year in consultations_clean. By how many percent did they grow
--from 2024 to 2025 (calculate by hand)? Why should 2023 and 2026 not be compared with the other
--years?

SELECT SUBSTR(CAST(consult_date AS TEXT), 1, 4) AS year,
       COUNT(*) AS n_consultations,
       COUNT(DISTINCT patient_id)AS n_patients
FROM   consultations_clean
GROUP BY year
ORDER BY year;
-- Croissance 2024 -> 2025 : (1 715 - 1 471) / 1 471 x 100 = +16,6 %.
-- Car 2026 est incomplète : les données s'arrêtent le 22/06/2026 (un demi-an)
-- 2023 est le début de la collecte , le tout n'est pas encore suivi
-- X5 : Raw (avant nettoyage) , 2024 = 1471 ; 2025 = 1716 
--     Clean in sql : 2024 : 1471 ; 2025: 1715 ----> du au doublon P554 de 2025


-- Q4.4 :  Count the consultations per type, most frequent first

SELECT consult_type,
       COUNT(*)AS n_consultations,
       COUNT(DISTINCT patient_id) AS n_patients,
       ROUND(100.0 * COUNT(*) / 3608, 1)AS pct_consultations
FROM consultations_clean
GROUP BY consult_type
ORDER BY n_consultations DESC;

-- Q4.5 : How many measurements show a glucose of 126 mg/dL or more, and how many different patients
-- do they concern?

SELECT COUNT(*) AS n_measurements,
       COUNT(DISTINCT patient_id) AS n_patients
FROM glucose_history
WHERE glucose_mg_dl >= 126;

-- on a donc 5.5 mesure elevé en moyenne par patients concerné 
-- Comparaison avec la Q1.5 : 50 patients >= 126 à la mesure de référence
-- (table patients), mais 82 dans l'historique. Les 50 sont tous inclus dans
-- les 82 ; 32 patients ont donc dépassé le seuil à un moment du suivi
-- sans être au-dessus au départ.

--Q4.6  Give the number of measurements and the average HbA1c (2 decimals) per year. Does HbA1c
--      change over time?

SELECT SUBSTR(CAST(measure_date AS TEXT), 1, 4)  AS year,
       COUNT(*)AS n_measurements,
       ROUND(CAST(AVG(hba1c_pct) AS NUMERIC), 2) AS avg_hba1c
FROM   glucose_history
GROUP BY year
ORDER BY year;

-- Réponse : non, l'HbA1c ne change pas au cours du temps : les variations
-- sont de l'ordre de 0,05 point. il ne faut pas oublier que les quatres premières lignes ne sont que les mesures du centre C21
-- L'hémoglobine glyquées au dessus de 6.5% peut etre considéré comme diabétique selon de ce que je me souviens de mes cours
-- de pharma. dés lors la glycémie moyenne me parais relativement basse (93.3). il y a peut etre quelque chose à analyser ici

-- Q4.7   How many treatments are still ongoing (no end date), not counting the rows Aucun traitement?

SELECT COUNT(*)AS n_ongoing_treatments,
       COUNT(DISTINCT patient_id) AS n_patients
FROM treatments
WHERE end_date IS NULL
  AND drug_class <> 'Aucun traitement';

-- Les aucun traitement n'ont pas de date de fin (rien à arreter) il faut donc effectivement les exclure aussi

-- Part A5 — Combining tables. 
-- Q5.1 Join patients and lifestyle to give the number of patients and their average glucose for each
--      stress level. What do you notice?

SELECT COUNT(*) AS n_rows
FROM   patients p
JOIN   lifestyle l ON l.patient_id = p.patient_id;

SELECT l.stress_level,
       COUNT(*)AS n_patients,
       ROUND(CAST(AVG(p.glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients p
JOIN   lifestyle l ON l.patient_id = p.patient_id
GROUP BY l.stress_level
ORDER BY avg_glucose;

-- On peut observer que la glycémie moyenne augmente avec le niveau de stress
-- X9 : Clean in sql : Faible = 90.6 / modéré = 93 / élevé = 96.7

-- Q5.2  Same question for activity_level, then for smoker. Which factor seems linked to glucose, and
--       which does not?

SELECT l.activity_level,
       COUNT(*)AS n_patients,
       ROUND(CAST(AVG(p.glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients p
JOIN   lifestyle l ON l.patient_id = p.patient_id
GROUP BY l.activity_level
ORDER BY avg_glucose;

SELECT l.smoker,
       COUNT(*)AS n_patients,
       ROUND(CAST(AVG(p.glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients p
JOIN   lifestyle l ON l.patient_id = p.patient_id
GROUP BY l.smoker
ORDER BY avg_glucose;

-- Les facteurs qui semblent influencer la glycémie sont donc le stress et l'activité physique. 
-- Le tabagisme ne semble pas lié à une glycémie moyenne plus élevé

-- Q5.3 Count the patients per region. You need patient_centre and care_centres  X8 

SELECT c.region,
       COUNT(*) AS n_patients
FROM   patient_centre pc
JOIN   care_centres c ON c.centre_id = pc.centre_id
GROUP BY c.region
ORDER BY n_patients DESC;

--Q5.4 Give the number of patients and the average glucose for each type of care centre. This time you
--     need three tables.

SELECT c.centre_type,
       COUNT(*) AS n_patients,
       ROUND(CAST(AVG(p.glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients p
JOIN   patient_centre pc ON pc.patient_id = p.patient_id
JOIN   care_centres c    ON c.centre_id   = pc.centre_id
GROUP BY c.centre_type
ORDER BY avg_glucose DESC;


--Q5.5 Compare the patients who have at least one relative with type 2 diabetes with the others: number
--     of patients and average glucose for each group. [X6] 


-- Au moins un parent avec un diabète de type 2 

SELECT COUNT(*)AS n_patients,
       ROUND(CAST(AVG(glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients
WHERE  patient_id IN
         (SELECT patient_id
          FROM   family_history_clean
          WHERE  condition = 'Diabète de type 2');

-- 117 patients et glycémie moyenne de 101.0 mg/dl

-- Aucun parent avec un diabète de type 2 : 

SELECT COUNT(*) AS n_patients,
       ROUND(CAST(AVG(glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   patients
WHERE  patient_id NOT IN
         (SELECT patient_id
          FROM   family_history_clean
          WHERE  condition = 'Diabète de type 2');
-- 1383 patients avec une moyenne de 92.8 mg/dl

-- celà fait bien 1500 patients

-- On peut donc en conclure que les patients avec un parent diabétique ont une glycémie moyenne
-- plus élevée de 8,2 mg/dL (101,0 contre 92,8)

-- X6 : Clean in Sql : avec un parent diabétique de type 2 : 101.0 
--                     sans parent diabétique de type 2 : 92.8 


-- Q5.6 : For each antidiabetic drug, give the number of patients and their average glucose. Why is glucose
--        so high for the three rare drugs?

SELECT t.drug_name,
       COUNT(DISTINCT t.patient_id) AS n_patients,
       ROUND(CAST(AVG(p.glucose_mg_dl) AS NUMERIC), 1) AS avg_glucose
FROM   treatments t
JOIN   patients p ON p.patient_id = t.patient_id
WHERE  t.drug_class = 'Antidiabétiques'
GROUP BY t.drug_name
ORDER BY n_patients DESC;

-- Metformine : 1345 patient et moyenne de 95.6 
-- Empagliflozine : 12 P et moyenne de 144 
-- Insuline glargine : 9 P et moyenne de 157.1 
-- Sémaglutide : 9 P et moyenne de 157.8 

-- Généralement ces médicaments rares sont des traitements de deuxième ligne rajouté quand la metformine seule
-- ne performe plus assez. Leur diabète est donc plus compliqué à gérer.Ce qui explique la plus haute moyenne. 
-- Ce sont des patients avec des cas plus avancés de diabète et des varitations de glycémie importante. On a un biais ici. 
-- La moyenne est aussi tiré par les extremes qui ici seront présent par le peu de patient et les fluctuations importante



-- Q5.7 : Critical thinking. Count the patients per stress level among those who received an antidepressant,
--        then among the others. Would you expect this result? What does it say about the data?

--1. Patient ayant reçu un antidépresseur

SELECT l.stress_level,
       COUNT(*) AS n_patients,
       ROUND(100.0 * COUNT(*) / 120, 1) AS pct_group
FROM   lifestyle l
WHERE  l.patient_id IN
         (SELECT patient_id
          FROM   treatments
          WHERE  drug_class = 'Antidépresseurs')
GROUP BY l.stress_level
ORDER BY MIN(l.stress_score);

-- Faible : 34 (28.3%)/ Modéré : 58 (48.3%) / Elevé : 28 ( 23.3%)


--2. Les autres patients

SELECT l.stress_level,
       COUNT(*)AS n_patients,
       ROUND(100.0 * COUNT(*) / 1380, 1) AS pct_group
FROM   lifestyle l
WHERE  l.patient_id NOT IN
         (SELECT patient_id
          FROM   treatments
          WHERE  drug_class = 'Antidépresseurs')
GROUP BY l.stress_level
ORDER BY MIN(l.stress_score);

-- Faible : 336 (24.3%) / Modéré ; 672 ( 48.7%) / Elevé : 372 (27%)

-- On observe que la répartition ne différe pas beaucoup , il y a moins de stress elevé par contre
-- Je ne m'attendais pas à ce résultat, on pourrait penser que les patients sous antidépresseur sont plus stressé. 
-- Dans le contexte on voit que le questionnaire d'hygiène est pas daté. 
-- Les traitements antidépresseur ont une date de fin, ce sont des traitement visiblement terminé. 
-- En tant que pharmacien je sais aussi que la prise d'AD peut aussi etre lié à d'autres foctions que une reductio de stress
-- Les douleurs neuopathiques et les problèmes de sommeil sont aussi des indications de ces molécules. 
-- Dés lors comment dire que c'était d'office pour le stress que leur prise a été indiqué. 

-- Q5.8 Find the last measurement date in glucose_history (MAX). Then list the treatments that start
--      after that date. Is that possible?

-- 1. Date de la dernière mesure

SELECT MAX(measure_date) AS last_measure_date
FROM   glucose_history;

-- 28/06/2026

--2. Traitements qui commencent après cette date. 

SELECT patient_id, drug_name, drug_class, start_date, end_date
FROM   treatments
WHERE  start_date > '2026-06-28'
ORDER BY start_date;

-- 1 antihistaminique et 5 antibiotique

-- Ici visiblement les traitement ont une date de fin défini ou c'est une erreur d'encodage
-- on a quand meme 4 patient qui commence le meme traitement pour la meme durée. 
-- ça pourrait etre une erreur d'encodage. 
