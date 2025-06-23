# Exercice 2 : Requêtes avec filtres multiple
## 2.1 Requête avec conditions multiples
```sql
EXPLAIN ANALYZE
SELECT *
FROM title_basics
WHERE title_type = 'movie'
AND start_year = 1950;
```
```sql
"Bitmap Heap Scan on title_basics  (cost=87.23..25993.49 rows=480 width=86) (actual time=4.555..778.101 rows=2009 loops=1)"
"  Recheck Cond: (start_year = 1950)"
"  Filter: ((title_type)::text = 'movie'::text)"
"  Rows Removed by Filter: 6268"
"  Heap Blocks: exact=3275"
"  ->  Bitmap Index Scan on idx_start_year  (cost=0.00..87.11 rows=7823 width=0) (actual time=3.640..3.640 rows=8277 loops=1)"
"        Index Cond: (start_year = 1950)"
"Planning Time: 0.829 ms"
"Execution Time: 778.287 ms"
```

## 2.2 Analyse du plan d'exécution
**Quelle stratégie est utilisée pour le filtre sur start_Year ?**
Un scan de bitmap est utilisé pour le filtre sur start_year, ce qui est efficace pour les requêtes avec des conditions sur une seule colonne.

**Comment est traité le filtre sur title_Type ?**
Le filtre sur title_type est appliqué après le scan de bitmap, en utilisant un filtre sur les lignes récupérées par le scan de bitmap. Cela signifie que toutes les lignes correspondant à start_year sont d'abord récupérées, puis celles qui correspondent à title_type sont filtrées.

**Combien de lignes passent le premier filtre, puis le second ?**
8277 lignes passent le premier filtre (start_year = 1950), et 2009 lignes passent le second filtre (title_type = 'movie').

**Quelles sont les limitations de notre index actuel ?**
L'index actuel est limité car il ne couvre qu'une seule colonne (start_year). Cela signifie que le filtre sur title_type doit être appliqué après le scan de bitmap, ce qui peut être inefficace si le nombre de lignes correspondant à start_year est élevé.

## 2.3 Index composite
```sql
CREATE INDEX idx_start_year_title_type
ON title_basics (start_year, title_type);
```

## 2.4 Analyse après index composite 
```sql
"Bitmap Heap Scan on title_basics  (cost=9.36..1860.89 rows=480 width=86) (actual time=2.991..17.916 rows=2009 loops=1)"
"  Recheck Cond: ((start_year = 1950) AND ((title_type)::text = 'movie'::text))"
"  Heap Blocks: exact=933"
"  ->  Bitmap Index Scan on idx_start_year_title_type  (cost=0.00..9.24 rows=480 width=0) (actual time=2.621..2.621 rows=2009 loops=1)"
"        Index Cond: ((start_year = 1950) AND ((title_type)::text = 'movie'::text))"
"Planning Time: 4.186 ms"
"Execution Time: 18.000 ms"
```
On passe de 778 ms à 18 ms de temps d'exécution, toujours en bitmap, mais sans second filtre.

## 2.5 Impact du nombre de colonnes
```sql
EXPLAIN ANALYZE
SELECT tconst, primary_title, start_year, title_type
FROM title_basics
WHERE title_type = 'movie'
AND start_year = 1950;
```

```sql
"Bitmap Heap Scan on title_basics  (cost=9.36..1860.89 rows=480 width=44) (actual time=0.184..1.015 rows=2009 loops=1)"
"  Recheck Cond: ((start_year = 1950) AND ((title_type)::text = 'movie'::text))"
"  Heap Blocks: exact=933"
"  ->  Bitmap Index Scan on idx_start_year_title_type  (cost=0.00..9.24 rows=480 width=0) (actual time=0.092..0.093 rows=2009 loops=1)"
"        Index Cond: ((start_year = 1950) AND ((title_type)::text = 'movie'::text))"
"Planning Time: 0.102 ms"
"Execution Time: 1.073 ms"
```
**Le temps d'exécution a-t-il changé ?**
Le temps est encore plus rapide, de 1 ms au lieu de 18 ms avant.

**Pourquoi cette optimisation est-elle plus ou moins efficace que dans l'exercice 1 ?**
Cette optimisation est plus efficace que celle de l'exercice 1, car l'index composite couvre les deux colonnes utilisées dans le filtre.

**Dans quel cas un "covering index" (index qui contient toutes les colonnes de la requête) serait
idéal ?**
Un covering index est idéal lorsque toutes les colonnes de la requête sont couvertes par l'index.

## 2.6 Analyse de l'amélioration globale 
**Quelle est la différence de temps d'exécution par rapport à l'étape 2.1 ?**
Nous sommes passés de 778 ms à 1 ms, une amélioration considérable.

**Comment l'index composite modifie-t-il la stratégie ?**
L'index composite permet de combiner les conditions de filtre sur start_year et title_type dans un seul scan de bitmap, évitant ainsi un second filtre après le scan. Cela réduit le temps d'exécution et améliore l'efficacité globale de la requête.

**Pourquoi le nombre de blocs lus ("Heap Blocks") a-t-il diminué ?**
Le nombre de blocs lus a diminué car l'index composite permet de récupérer directement les lignes correspondant aux deux conditions de filtre, réduisant ainsi le nombre de blocs nécessaires pour accéder aux données.

**Dans quels cas un index composite est-il particulièrement efficace ?**
Un index composite est donc meilleur sur une requête faisant un SELECT sur les lignes qu'il indexe.

