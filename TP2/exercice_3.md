# 3 - Jointures et filtres

## 3.1 - Jointure avec filtres
Query : 
``` sql
EXPLAIN ANALYZE
SELECT b.primary_title, r.average_rating
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.title_type = 'movie'
  AND b.start_year = 1994
  AND r.average_rating > 8.5;
```
Résultat de la query :

> | Query Plan  |
> | :--------------- |
> | Gather  (cost=1000.43..259117.00 rows=48 width=27) (actual time=90.217..5453.560 rows=37 loops=1)  |   
> | Workers Planned: 2  | 
> | Workers Launched: 2  |
> |   ->  Nested Loop  (cost=0.43..258112.20 rows=20 width=27) (actual time=42.843..5374.378 rows=12 loops=3) |
> |   ->  Nested Loop  (cost=0.43..258112.20 rows=20 width=27) (actual time=42.843..5374.378 rows=12 loops=3) |
> |         ->  Parallel Seq Scan on title_basics b  (cost=0.00..247162.56 rows=1598 width=31) (actual time=27.022..4639.909 rows=1417 loops=3) |
> |               Filter: (((title_type)::text = 'movie'::text) AND (start_year = 1994)) |
> |               Rows Removed by Filter: 3910203 |
> |         ->  Index Scan using title_ratings_pkey on title_ratings r  (cost=0.43..6.85 rows=1 width=16) (actual time=0.517..0.517 rows=0 loops=4252) |
> |               Index Cond: ((tconst)::text = (b.tconst)::text) |
> |               Filter: (average_rating > 8.5) |
> |               Rows Removed by Filter: 1 |
> | Planning Time: 4.945 ms |
> | JIT: |
> |   Functions: 30 |
> |   Options: Inlining false, Optimization false, Expressions true, Deforming true |
> |   Timing: Generation 6.076 ms (Deform 0.477 ms), Inlining 0.000 ms, Optimization 0.606 ms, Emission 17.014 ms, Total 23.697 ms |
> | Execution Time: 5453.843 ms |

## 3.2 - Analyse du plan de jointure

1. Quel algorithme de jointure est utilisé?
> L'alogrithme de jointure utilisé est Nested Loop.

2. Comment l'index sur start_Year est-il utilisé?
> L'index sur start_Year n’est pas utilisé. L’absence d’index sur le champ oblige PostgreSQL à parcourir toute la table.

3. Comment est traitée la condition sur average_Rating?
> La condition sur average_Rating est filtrée après un index scan sur la clé primaire.

4. Pourquoi PostgreSQL utilise-t-il le parallélisme?
> Pour accélérer la lecture séquentielle de title_basics

## 3.3 Indexation de la seconde condition

``` sql
CREATE INDEX idx_title_ratings_average_rating
ON title_ratings (average_rating);

```

## 3.4 Analyse après indexation

Résultat de la query après création de l'index :

> | Query Plan  |
> | :--------------- |
> | Gather  (cost=1000.43..259117.00 rows=48 width=27) (actual time=14.746..245.890 rows=37 loops=1) |
> |   Workers Planned: 2 |
> |   Workers Launched: 2 |
> |   ->  Nested Loop  (cost=0.43..258112.20 rows=20 width=27) (actual time=9.571..234.283 rows=12 loops=3) |
> |         ->  Parallel Seq Scan on title_basics b  (cost=0.00..247162.56 rows=1598 width=31) (actual time=7.758..227.845 rows=1417 loops=3) |
> |               Filter: (((title_type)::text = 'movie'::text) AND (start_year = 1994)) |
> |               Rows Removed by Filter: 3910203 |
> |         ->  Index Scan using title_ratings_pkey on title_ratings r  (cost=0.43..6.85 rows=1 width=16) (actual time=0.004..0.004 rows=0 loops=4252) |
> |               Index Cond: ((tconst)::text = (b.tconst)::text) |
> |               Filter: (average_rating > 8.5) |
> |               Rows Removed by Filter: 1 |
> | Planning Time: 0.318 ms |
> | JIT: |
> |   Functions: 30 |
> |   Options: Inlining false, Optimization false, Expressions true, Deforming true |
> |   Timing: Generation 1.036 ms (Deform 0.629 ms), Inlining 0.000 ms, Optimization 0.586 ms, Emission 12.216 ms, Total 13.838 ms |
> | Execution Time: 246.152 ms |

Différences notables entre les deux exécutions :

| Comparaison | Sans index  | Avec Index |
| :--- | :--- | :--- |
| Execution Time | 5453.843 ms | 246.152 ms |
| actual time (Index Scan) | 0.517 ms par itération | 0.004 ms par itération |
| Nested Loop (actual time) | 42.843..5374.378 ms | 9.571..234.283 ms |
| Planning Time | 4.945 ms | 0.318 ms |
| JIT Generation | 23.697 ms | 13.838 ms |

## 3.5 Analyse de l'impact

1. L'algorithme de jointure a-t-il changé?
> Non l'algotithme n'a pas changé.

2. Comment l'index sur average_Rating est-il utilisé?
> Il est utilisé indirectement pour optimiser le filtre average_rating > 8.5 après l’accès par clé primaire

3. Le temps d'exécution s'est-il amélioré? Pourquoi?
> L’accès à title_ratings est plus rapide car l’évaluation de average_rating est plus performante grace à l'index.

4. Pourquoi PostgreSQL abandonne-t-il le parallélisme?
> PostgreSQL n’utilise pas le parallélisme si il fait un Index Scan basé sur une jointure car le coût du parralelisme serait plus élever.
