# Exercice 4 : Agrégation et tri
## 4.1 Requête complexe
```sql
EXPLAIN ANALYZE
SELECT tb.start_year,
       COUNT(*) AS nb_movies,
       AVG(tr.average_rating) AS average_rating
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.title_type = 'movie'
AND tb.start_year BETWEEN 1990 AND 2000

GROUP BY tb.start_year
ORDER BY average_rating DESC;
```
```sql
"Sort  (cost=149472.35..149472.69 rows=135 width=44) (actual time=1269.597..1279.623 rows=11 loops=1)"
"  Sort Key: (avg(tr.average_rating)) DESC"
"  Sort Method: quicksort  Memory: 25kB"
"  ->  Finalize GroupAggregate  (cost=149399.71..149467.57 rows=135 width=44) (actual time=1268.602..1279.612 rows=11 loops=1)"
"        Group Key: tb.start_year"
"        ->  Gather Merge  (cost=149399.71..149463.18 rows=270 width=44) (actual time=1268.396..1279.568 rows=33 loops=1)"
"              Workers Planned: 2"
"              Workers Launched: 2"
"              ->  Partial GroupAggregate  (cost=148399.69..148431.99 rows=135 width=44) (actual time=1244.639..1245.686 rows=11 loops=3)"
"                    Group Key: tb.start_year"
"                    ->  Sort  (cost=148399.69..148407.34 rows=3062 width=10) (actual time=1244.486..1244.905 rows=10346 loops=3)"
"                          Sort Key: tb.start_year"
"                          Sort Method: quicksort  Memory: 719kB"
"                          Worker 0:  Sort Method: quicksort  Memory: 700kB"
"                          Worker 1:  Sort Method: quicksort  Memory: 704kB"
"                          ->  Parallel Hash Join  (cost=129807.64..148222.39 rows=3062 width=10) (actual time=1049.417..1243.222 rows=10346 loops=3)"
"                                Hash Cond: ((tr.tconst)::text = (tb.tconst)::text)"
"                                ->  Parallel Seq Scan on title_ratings tr  (cost=0.00..16685.11 rows=658911 width=16) (actual time=0.235..123.010 rows=527129 loops=3)"
"                                ->  Parallel Hash  (cost=129523.58..129523.58 rows=22725 width=14) (actual time=1043.290..1043.291 rows=17113 loops=3)"
"                                      Buckets: 65536  Batches: 1  Memory Usage: 2976kB"
"                                      ->  Parallel Bitmap Heap Scan on title_basics tb  (cost=14195.44..129523.58 rows=22725 width=14) (actual time=89.632..1034.553 rows=17113 loops=3)"
"                                            Recheck Cond: ((start_year >= 1990) AND (start_year <= 2000) AND ((title_type)::text = 'movie'::text))"
"                                            Heap Blocks: exact=5933"
"                                            ->  Bitmap Index Scan on idx_start_year_title_type  (cost=0.00..14181.81 rows=54540 width=0) (actual time=71.160..71.161 rows=51338 loops=1)"
"                                                  Index Cond: ((start_year >= 1990) AND (start_year <= 2000) AND ((title_type)::text = 'movie'::text))"
"Planning Time: 9.272 ms"
"JIT:"
"  Functions: 57"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 18.760 ms (Deform 4.375 ms), Inlining 0.000 ms, Optimization 13.058 ms, Emission 102.093 ms, Total 133.911 ms"
"Execution Time: 1296.529 ms"
```

## 4.2 Analyse du plan complexe
**Identifiez les différentes étapes du plan (scan, hash, agrégation, tri)**
1. **Bitmap Index Scan** : Scan bitmap sur `idx_start_year_title_type` pour filtrer les lignes de `title_basics` qui correspondent aux conditions `start_year BETWEEN 1990 AND 2000` et `title_type = 'movie'`.
2. **Parallel Bitmap Heap Scan** : Scan bitmap sur `title_basics` pour récupérer les lignes filtrées.
3. **Parallel Hash Join** : Jointure entre `title_basics` et `title_ratings` sur la colonne `tconst`.
4. **Sort** : Tri des résultats par `average_rating` en ordre décroissant.
5. **GroupAggregate** : Agrégation finale pour regrouper les résultats par `start_year` et calculer le nombre de films et la moyenne des évaluations.

**Pourquoi l'agrégation est-elle réalisée en deux phases ("Partial" puis "Finalize") ?**
L'agrégation est réalisée en deux phases pour permettre une exécution parallèle efficace. La phase "Partial" agrège les résultats localement dans chaque worker, ce qui réduit la quantité de données à transférer et à traiter dans la phase "Finalize". Cela permet d'améliorer les performances en réduisant le temps de traitement global.

**Comment sont utilisés les index existants ?**
Les index existants sont utilisés pour optimiser le filtrage des lignes dans `title_basics` et `title_ratings`. Le scan d'index bitmap sur `idx_start_year_title_type` permet de rapidement identifier les lignes pertinentes dans `title_basics`, tandis que le scan de la clé primaire sur `title_ratings` permet de récupérer les évaluations correspondantes sans avoir à parcourir toute la table.

**Le tri final est-il coûteux ? Pourquoi ?**
Le tri final est relativement coûteux, car il nécessite de trier les résultats agrégés par `average_rating` en ordre décroissant. Cependant, le coût est atténué par l'utilisation de la méthode de tri "quicksort", qui est efficace pour les ensembles de données de taille modérée. De plus, la mémoire utilisée pour le tri est raisonnable (25kB), ce qui indique que le tri peut être effectué en mémoire sans nécessiter d'opérations de disque coûteuses.

## 4.3 Indexation des colonnes de jointure
```sql
CREATE INDEX idx_title_basics_tconst
ON title_basics (tconst);

CREATE INDEX idx_title_ratings_tconst
ON title_ratings (tconst);
```

## 4.4 Analyse après indexation
```sql
"Sort  (cost=149472.35..149472.69 rows=135 width=44) (actual time=942.433..954.085 rows=11 loops=1)"
"  Sort Key: (avg(tr.average_rating)) DESC"
"  Sort Method: quicksort  Memory: 25kB"
"  ->  Finalize GroupAggregate  (cost=149399.71..149467.57 rows=135 width=44) (actual time=941.091..953.745 rows=11 loops=1)"
"        Group Key: tb.start_year"
"        ->  Gather Merge  (cost=149399.71..149463.18 rows=270 width=44) (actual time=940.940..953.700 rows=33 loops=1)"
"              Workers Planned: 2"
"              Workers Launched: 2"
"              ->  Partial GroupAggregate  (cost=148399.69..148431.99 rows=135 width=44) (actual time=911.742..912.727 rows=11 loops=3)"
"                    Group Key: tb.start_year"
"                    ->  Sort  (cost=148399.69..148407.34 rows=3062 width=10) (actual time=911.560..911.981 rows=10346 loops=3)"
"                          Sort Key: tb.start_year"
"                          Sort Method: quicksort  Memory: 720kB"
"                          Worker 0:  Sort Method: quicksort  Memory: 698kB"
"                          Worker 1:  Sort Method: quicksort  Memory: 706kB"
"                          ->  Parallel Hash Join  (cost=129807.64..148222.39 rows=3062 width=10) (actual time=709.483..910.246 rows=10346 loops=3)"
"                                Hash Cond: ((tr.tconst)::text = (tb.tconst)::text)"
"                                ->  Parallel Seq Scan on title_ratings tr  (cost=0.00..16685.11 rows=658911 width=16) (actual time=0.621..130.697 rows=527129 loops=3)"
"                                ->  Parallel Hash  (cost=129523.58..129523.58 rows=22725 width=14) (actual time=703.529..703.530 rows=17113 loops=3)"
"                                      Buckets: 65536  Batches: 1  Memory Usage: 2944kB"
"                                      ->  Parallel Bitmap Heap Scan on title_basics tb  (cost=14195.44..129523.58 rows=22725 width=14) (actual time=59.746..696.346 rows=17113 loops=3)"
"                                            Recheck Cond: ((start_year >= 1990) AND (start_year <= 2000) AND ((title_type)::text = 'movie'::text))"
"                                            Heap Blocks: exact=5556"
"                                            ->  Bitmap Index Scan on idx_start_year_title_type  (cost=0.00..14181.81 rows=54540 width=0) (actual time=59.991..59.992 rows=51338 loops=1)"
"                                                  Index Cond: ((start_year >= 1990) AND (start_year <= 2000) AND ((title_type)::text = 'movie'::text))"
"Planning Time: 5.932 ms"
"JIT:"
"  Functions: 57"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 13.635 ms (Deform 3.350 ms), Inlining 0.000 ms, Optimization 9.244 ms, Emission 65.189 ms, Total 88.067 ms"
"Execution Time: 966.302 ms"
```

## 4.5 Analyse des résultats
**Les index de jointure sont-ils utilisés ? Pourquoi ?**
Oui, les index de jointure sont utilisés. Le plan d'exécution montre un "Parallel Hash Join" entre `title_basics` et `title_ratings`, ce qui indique que PostgreSQL utilise les index pour optimiser la jointure sur la colonne `tconst`. Cela permet de réduire le temps nécessaire pour trouver les correspondances entre les deux tables.

**Pourquoi le plan d'exécution reste-t-il pratiquement identique ?**
Le plan d'exécution reste pratiquement identique car les index créés n'ont pas modifié la structure fondamentale de la requête. Les étapes principales (scan, jointure, agrégation, tri) restent les mêmes, mais les index permettent d'optimiser certaines opérations, notamment le filtrage et la jointure, ce qui se traduit par une réduction du temps d'exécution.

**Dans quels cas les index de jointure seraient-ils plus efficaces ?**
Les index de jointure seraient plus efficaces s'il y avait plus de lignes dans les tables jointes, ou si les conditions de jointure étaient plus complexes.