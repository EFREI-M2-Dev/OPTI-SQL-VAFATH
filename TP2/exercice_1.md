
# 📊 Analyse de requêtes SQL avec `EXPLAIN ANALYZE`

## 1.1 Première analyse

**Requête :**

```sql
EXPLAIN ANALYZE
SELECT *
FROM public.title_basics
WHERE start_year = 2020;
```

**Résultat (extrait du plan d'exécution) :**

```text
Gather  (cost=1000.00..280749.50 rows=447823 width=84) (actual time=14.295..1027.530 rows=440009 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on title_basics  
        (cost=0.00..234967.20 rows=186593 width=84) 
        (actual time=9.394..988.050 rows=146670 loops=3)
        Filter: (start_year = 2020)
        Rows Removed by Filter: 3764950
Planning Time: 0.083 ms
Execution Time: 1066.190 ms
```

## 1.2 Analyse du plan d'exécution

**Éléments observés :**

* **Stratégie utilisée** : `Parallel Seq Scan` (scan séquentiel parallèle).
* **Nombre de lignes retournées** : `440009`.
* **Lignes examinées puis rejetées** : `3764950`.
* **Temps total d'exécution** : `1066.190 ms`.

**Réponses aux questions :**

1. **Pourquoi PostgreSQL utilise-t-il un `Parallel Sequential Scan` ?**
   Parce que la table est volumineuse et qu'aucun index n'existe encore sur la colonne `start_year`. Le planificateur estime qu’un scan parallèle est plus rapide qu’un index scan ou un scan séquentiel simple.

2. **La parallélisation est-elle justifiée ici ? Pourquoi ?**
   Oui, car le volume de données est très important. La requête retourne un nombre élevé de résultats, ce qui rend la parallélisation bénéfique.

3. **Que représente la valeur `Rows Removed by Filter` ?**
   Elle indique le nombre de lignes analysées mais exclues car leur champ `start_year` est différent de 2020.


## 1.3 Création d’un index

**Requête :**

```sql
CREATE INDEX idx_start_year ON public.title_basics(start_year);
```

**Résultat :**

L’index a été créé avec succès :

> `Query returned successfully in 3 secs 848 msec.`

 

## 1.4 Analyse après indexation

**Requête exécutée à nouveau :**

```sql
EXPLAIN ANALYZE
SELECT *
FROM public.title_basics
WHERE start_year = 2020;
```

**Nouveau résultat :**

```text
Gather  (cost=5991.51..274674.75 rows=447881 width=84) (actual time=36.971..1235.508 rows=440009 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Bitmap Heap Scan on title_basics  
        (cost=4991.51..228886.65 rows=186617 width=84) 
        (actual time=24.188..1197.578 rows=146670 loops=3)
        Recheck Cond: (start_year = 2020)
        Rows Removed by Index Recheck: 671753
        Heap Blocks: exact=11863 lossy=10606
        ->  Bitmap Index Scan on idx_start_year  
              (cost=0.00..4879.54 rows=447881 width=0) 
              (actual time=29.901..29.902 rows=440009 loops=1)
Execution Time: 1252.055 ms
```

**Observation :**
L’utilisation de l’index n’a pas significativement amélioré le temps d’exécution : il est même légèrement plus lent. Cela peut s’expliquer par le grand nombre de résultats retournés, qui ne rend pas l’indexation très avantageuse ici.

 

## 1.5 Impact du nombre de colonnes

**Requête modifiée :**

```sql
EXPLAIN ANALYZE
SELECT tconst, primary_title, start_year
FROM public.title_basics
WHERE start_year = 2020;
```

**Résultat :**

```text
Execution Time: 812.152 ms
```

**Comparaison :**

1. **Le temps d’exécution a-t-il changé ? Pourquoi ?**
   Oui, il a diminué. En ne sélectionnant que trois colonnes, le système doit lire et transférer moins de données, ce qui réduit le coût I/O et la charge mémoire.

2. **Le plan d’exécution est-il différent ?**
   Non, la stratégie de scan reste la même (`Parallel Bitmap Heap Scan`), mais le `width` (poids estimé des lignes) diminue, ce qui contribue à l'amélioration.

3. **Pourquoi la sélection de moins de colonnes peut-elle améliorer les performances ?**
   Moins de colonnes signifie moins de données à charger depuis le disque et à envoyer au client, ce qui réduit le temps de traitement global.

 

## 1.6 Analyse de l’impact global

**Comparaison avec l’étape 1.1 :**

1. **Nouvelle stratégie utilisée par PostgreSQL :**
   `Parallel Bitmap Heap Scan` + `Bitmap Index Scan`, au lieu de `Parallel Seq Scan`.

2. **Amélioration du temps d’exécution :**
   Le temps est passé de **1066 ms** (étape 1.1) à **812 ms** (étape 1.5) soit un **gain d’environ 25 %**.

3. **Définition :**

   * `Bitmap Index Scan` : lit toutes les entrées d’index qui satisfont la condition (ici `start_year = 2020`) et construit une **bitmap** (carte binaire).
   * `Bitmap Heap Scan` : utilise cette bitmap pour accéder efficacement aux lignes dans le fichier de données.

4. **Pourquoi l’amélioration n’est-elle pas plus importante ?**
   Car la requête retourne toujours un nombre très élevé de lignes. Même avec un index, PostgreSQL doit accéder à un grand volume de données, ce qui limite les gains potentiels.

