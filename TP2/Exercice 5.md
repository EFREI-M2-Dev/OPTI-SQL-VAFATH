# 5 - Recherche ponctuelle

## 5.1 Requête de recherche par identifiant

Query : 

``` sql
EXPLAIN ANALYZE
SELECT b.primary_title, r.average_rating
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.tconst = 'tt0111161';
```

Résultat de la query : 

> | Query Plan  |
> | :--------------- |
> | Nested Loop  (cost=0.86..16.91 rows=1 width=27) (actual time=0.889..0.891 rows=1 loops=1) |
> |   ->  Index Scan using title_basics_pkey on title_basics b  (cost=0.43..8.45 rows=1 width=31) (actual time=0.869..0.870 rows=1 loops=1) |
> |         Index Cond: ((tconst)::text = 'tt0111161'::text) |
> |   ->  Index Scan using title_ratings_pkey on title_ratings r  (cost=0.43..8.45 rows=1 width=16) (actual time=0.015..0.016 rows=1 loops=1) |
> |         Index Cond: ((tconst)::text = 'tt0111161'::text) |
> | Planning Time: 0.057 ms |
> | Execution Time: 0.904 ms |

## 5.2 Analyse du plan

1. Quel algorithme de jointure est utilisé cette fois?
> Nested Loop

2. Comment les index sur tconst sont-ils utilisés?
> Les deux index primaires sont exploités : Sur title_basics et sur title_ratings

3. Comparez le temps d'exécution avec les requêtes précédentes
> | Requete | Temps d'execution |
> | :--- | :--- |
> | Exercice 2.1 | 778.287 ms |
> | Exercice 2.4 | 18.000 ms |
> | Exercice 3.1 | 5453.843 ms |
> | Exercice 3.4 | 246.152 ms |
> | Exercice 4.1 | 1296.529 ms |
> | Exercice 5 | 0.904 ms |

4. Pourquoi cette requête est-elle si rapide?
> Cette requête est si rapide car PostgreSQL va directement chercher 1 ligne dans chaque table, sans boucle, sans scan, sans tri.
