# Exercice 4: Index partiels 
## 4.1 Identifier un sous-ensemble fréquent 
```sql
SELECT 
    start_year AS annee,
    COUNT(*) AS film_count
FROM 
    title_basics
WHERE 
    start_year IS NOT NULL
    AND title_type = 'movie'
GROUP BY 
    annee
ORDER BY 
    annee;
```
2010 possède le plus de films : 168439

## 4.2 Requête sur ce sous-ensemble
```sql
SELECT 
    *
FROM 
    title_basics
WHERE 
    start_year IS NOT NULL
	AND (start_year / 10) * 10 = 2010
    AND title_type = 'movie'
```

## 4.3 Création d'un index partiel
```sql
CREATE INDEX title_basics_2010s_idx
ON title_basics (tconst)
WHERE title_type = 'movie' AND start_year BETWEEN 2010 AND 2019;	
```

## 4.4 Comparaison avec index complet 
```text
"Gather  (cost=1000.00..272964.00 rows=3175 width=86) (actual time=16.985..1785.806 rows=168439 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on title_basics  (cost=0.00..271646.50 rows=1323 width=86) (actual time=24.614..1745.038 rows=56146 loops=3)"
"        Filter: ((start_year IS NOT NULL) AND ((title_type)::text = 'movie'::text) AND (((start_year / 10) * 10) = 2010))"
"        Rows Removed by Filter: 3855474"
"Planning Time: 0.142 ms"
"JIT:"
"  Functions: 6"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 1.584 ms (Deform 0.546 ms), Inlining 0.000 ms, Optimization 1.300 ms, Emission 15.689 ms, Total 18.573 ms"
"Execution Time: 1797.165 ms"
```
Aucun index utilisé

```text
"Gather  (cost=1000.00..335830.00 rows=631835 width=86) (actual time=4.325..2088.185 rows=443869 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on title_basics  (cost=0.00..271646.50 rows=263265 width=86) (actual time=4.755..2022.422 rows=147956 loops=3)"
"        Filter: ((start_year IS NOT NULL) AND ((title_type)::text = 'movie'::text) AND (((start_year / 10) * 10) <> 2010))"
"        Rows Removed by Filter: 3763664"
"Planning Time: 0.150 ms"
"JIT:"
"  Functions: 6"
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 1.153 ms (Deform 0.441 ms), Inlining 0.000 ms, Optimization 1.058 ms, Emission 12.177 ms, Total 14.389 ms"
"Execution Time: 2112.186 ms"
```
Aucun index utilisé, plus lent que la première car plus de lignes

```text
"idx_start_year"	"78 MB"
"title_basics_2010s_idx"	"5216 kB"
```

## 4.5 Analyse et réflexion
**Quels sont les avantages et inconvénients d'un index partiel ?**
Plus léger et rapide qu'un index complet, mais uniquement si la requête couvre le sous-ensemble indexé.

**Dans quels scénarios un index partiel est-il particulièrement utile ?**
Quand les requêtes visent souvent le sous-ensemble de l'index, pour optimiser les performances et si le sous-ensemble est bien plus petit que l'ensemble de la table.

**Comment déterminer si un index partiel est adapté à votre cas d'usage ?**
Filtre where fréquent, recherche de performances.