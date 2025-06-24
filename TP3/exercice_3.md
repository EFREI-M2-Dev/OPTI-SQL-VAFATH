# 3 - Index composites

## 3.1 Requête avec plusieurs conditions

Query :
``` sql
SELECT primary_title, start_year, genres
FROM title_basics
WHERE title_type = 'movie'
  AND start_year = 1994
  AND genres ILIKE '%Drama%';
```
Résultat de la Query : 

> | primary_title | start_year | genres |
> | :- | :- | :- |
> | Kaadhalan |	1994	| Action,Drama,Romance |
> | Alun Lewis: Death and Beauty |	1994	| Drama |
> | Angel 4: Undercover |	1994	| Action,Drama |
> | Instinct |	1994	| Drama,Thriller |
> | Roraima |	1994	| Drama |
> | Men Behind the Sun 3: A Narrow Escape |	1994	| Drama |
> | To Die, to Sleep |	1994	| Drama |
> | The Golden Years |	1994	| Drama |
> | Az álommenedzser |	1994	| Comedy,Drama |
> | ... |	...	| ... |

## 3.2 Test sans index

Query :
``` sql
EXPLAIN ANALYSE SELECT primary_title, start_year, genres
FROM title_basics
WHERE title_type = 'movie'
  AND start_year = 1994
  AND genres ILIKE '%Drama%';
```
Résultat de la Query : 

> |Query plan|
> | :- |
> |Bitmap Heap Scan on title_basics  (cost=679.16..125612.66 rows=1064 width=37) (actual time=10.532..4784.910 rows=1577 loops=1) |
> |  Recheck Cond: (start_year = 1994) |
> |  Filter: (((genres)::text ~~* '%Drama%'::text) AND ((title_type)::text = 'movie'::text)) |
> |  Rows Removed by Filter: 67387 |
> |  Heap Blocks: exact=20823 |
> |  ->  Bitmap Index Scan on idx_start_year  (cost=0.00..678.90 rows=62195 width=0) (actual time=4.224..4.225 rows=68964 loops=1) |
> |        Index Cond: (start_year = 1994) |
> |Planning Time: 0.157 ms |
> |JIT: |
> |  Functions: 6 |
> |  Options: Inlining false, Optimization false, Expressions true, Deforming true |
> |  Timing: Generation 0.295 ms (Deform 0.146 ms), Inlining 0.000 ms, Optimization 0.304 ms, Emission 2.591 ms, Total 3.190 ms |
> |Execution Time: 4785.489 ms |


## 3.3 Index sur colonnes individuelles
Index :
``` sql
CREATE INDEX idx_title_basics_start_year
  ON title_basics (start_year);

CREATE INDEX idx_title_basics_genres
  ON title_basics USING gin (string_to_array(genres, ','));
```

Résultat de la Query :
> |Query plan|
> | :- |
> |Bitmap Heap Scan on title_basics  (cost=679.16..125612.66 rows=1064 width=37) (actual time=6.825..79.540 rows=1577 loops=1)|
> |  Recheck Cond: (start_year = 1994)|
> |  Filter: (((genres)::text ~~* '%Drama%'::text) AND ((title_type)::text = 'movie'::text))|
> |  Rows Removed by Filter: 67387|
> |  Heap Blocks: exact=20823|
> |  ->  Bitmap Index Scan on idx_start_year  (cost=0.00..678.90 rows=62195 width=0) (actual time=2.132..2.133 rows=68964 loops=1)|
> |        Index Cond: (start_year = 1994)|
> |Planning Time: 0.141 ms|
> |JIT:|
> |  Functions: 6|
> |  Options: Inlining false, Optimization false, Expressions true, Deforming true|
> |  Timing: Generation 0.250 ms (Deform 0.141 ms), Inlining 0.000 ms, Optimization 0.250 ms, Emission 2.583 ms, Total 3.082 ms|
> |Execution Time: 79.896 ms|

Comparaison avec/sans index :

| Critère | sans index | avec index |
| :- | :- | :- |
| Type de plan | Bitmap Heap Scan| Bitmap Heap Scan |
| Temps d’accès à l’index | 4.224 ms| 2.132 ms |
| Temps d'exécution total | 4785.489 ms | 79.896 ms |
| Lignes retournées | 1577 | 1577 |
| Lignes filtrées | 67387 | 67387 |
| Planning Time | 0.157 ms | 0.141 ms |
| Execution Time | 4785.489 ms | 79.896 ms |

## 3.4 Index composite
Index :
``` sql
CREATE INDEX idx_genres_start_year
ON title_basics (genres, start_year);
```
Résultat de la Query :
> |Query plan|
> | :- |
> |itmap Heap Scan on title_basics  (cost=679.16..125612.66 rows=1064 width=37) (actual time=6.770..68.025 rows=1577 loops=1)
> |  Recheck Cond: (start_year = 1994)
> |  Filter: (((genres)::text ~~* '%Drama%'::text) AND ((title_type)::text = 'movie'::text))
> |  Rows Removed by Filter: 67387
> |  Heap Blocks: exact=20823
> |  ->  Bitmap Index Scan on idx_start_year  (cost=0.00..678.90 rows=62195 width=0) (actual time=2.315..2.315 rows=68964 loops=1)
> |        Index Cond: (start_year = 1994)
> |Planning Time: 2.150 ms
> |JIT:
> |  Functions: 6
> |  Options: Inlining false, Optimization false, Expressions true, Deforming true
> |  Timing: Generation 0.256 ms (Deform 0.147 ms), Inlining 0.000 ms, Optimization 0.243 ms, Emission 2.403 ms, Total 2.902 ms
> |Execution Time: 68.380 ms

Comparaison sans Index / avec Index Simple / avec Index Composite :

| Critère| Sans index | Avec index simple | Avec index composite|
| :- | :- | :- | :- |
| Type de plan| Bitmap Heap Scan | Bitmap Heap Scan| Bitmap Heap Scan|
| Temps d’accès à l’index| 4.224 ms| 2.132 ms| 2.315 ms|
| Temps d'exécution total| 4785.489 ms| 79.896 ms| 68.380 ms|
| Lignes retournées| 1577| 1577| 1577|
| Lignes filtrées| 67387| 67387| 67387|
| Planning Time| 0.157 ms| 0.141 ms| 2.150 ms|
| Execution Time| 4785.489 ms| 79.896 ms| 68.380 ms|


## 3.5 Test de l'ordre des colonnes
Index :
``` sql
CREATE INDEX idx_start_year_genres
ON title_basics (start_year, genres);
```

Query : 
``` sql
-- 1 - genre
EXPLAIN ANALYZE
SELECT primary_title
FROM title_basics
WHERE genres = 'Drama';

-- 2 - année
EXPLAIN ANALYZE
SELECT primary_title
FROM title_basics
WHERE start_year = 1994;

-- 3 - genre et année
EXPLAIN ANALYZE
SELECT primary_title
FROM title_basics
WHERE genres = 'Drama'
  AND start_year = 1994;

-- 4 - genre puis année
EXPLAIN ANALYZE
SELECT primary_title
FROM title_basics
ORDER BY genres, start_year;

-- 5 - année puis genre
EXPLAIN ANALYZE
SELECT primary_title
FROM title_basics
ORDER BY start_year, genres;
```

Comparaison des différentes requêtes :
| Cas | Requête testée  | Index utilisé | Type de plan  | Temps d’accès index | Temps d'exécution total |
| :- | :- | :- | :- | :- | :- |
| 1| WHERE genres = 'Drama'  | idx_genres_start_year | Bitmap Index Scan - Heap Scan | 43.656 ms| 840.884 ms  |
| 2| WHERE start_year = 1994 | idx_start_year  | Bitmap Index Scan - Heap Scan | 4.325 ms | 5189.652 ms |
| 3| WHERE genres = 'Drama' AND start_year = 1994 | idx_start_year_genres | Bitmap Index Scan - Heap Scan | 2.899 ms | 5.661 ms |
| 4| ORDER BY genres, start_year| idx_genres_start_year | Index Scan  | —  | 7478.589 ms |
| 5| ORDER BY start_year, genres| idx_start_year_genres | Index Scan  | —  | 31152.206 ms |


## 3.6 Analyse et réflexion
1. Comment l'ordre des colonnes dans l'index composite affecte-t-il son utilisation?
> L’ordre des colonnes détermine quelles requêtes peuvent exploiter l’index directement

2. Quand un index composite est-il préférable à plusieurs index séparés?
> Un index composite est préférable à plusieurs index séparés quand les colonnes sont souvent filtrées ou triées ensemble dans les requêtes et que la requête cible des combinaisons de colonnes.

3. Comment choisir l'ordre optimal des colonnes dans un index composite?
> Le choix des colonnes se fait sur les plus filtrantes, les plus utilisées seules et leur fréquence d'utilisation.
