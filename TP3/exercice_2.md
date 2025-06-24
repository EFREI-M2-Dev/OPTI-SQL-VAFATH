# Exercice 2: Index Hash
## 2.1 Requête d'égalité exacte
```sql
EXPLAIN ANALYZE
SELECT *
FROM title_basics
WHERE tconst = 'tt0000001';
```

```text
"Index Scan using title_basics_pkey on title_basics  (cost=0.43..8.45 rows=1 width=86) (actual time=0.017..0.018 rows=1 loops=1)"
"  Index Cond: ((tconst)::text = 'tt0000001'::text)"
"Planning Time: 0.048 ms"
"Execution Time: 0.026 ms"
```

## 2.2 Création d'un index Hash
```sql
CREATE INDEX title_basics_tconst_hash_idx
ON title_basics USING HASH (tconst);
```

## 2.3 Comparaison avec B-tree
Le temps de recherche avec les deux index est similaire.

```sql

SELECT 
    indexrelid::regclass AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size_pretty,
    pg_relation_size(indexrelid) AS size_bytes
FROM 
    pg_index
WHERE 
    indexrelid::regclass::text IN (
        'title_basics_tconst_hash_idx',
        'title_basics_tconst_btree_idx'
    );
```

```text
"title_basics_tconst_hash_idx"	"321 MB"
"title_basics_tconst_btree_idx"	"353 MB"
```

L'index HASH fonctionne parfaitement pour les recherches par égalité, mais il n'est pas optimisé pour des recherches par plage, où l'index B-TREE est plus performant.

## 2.4 Analyse et réflexion 
**Quelles sont les différences de performance entre Hash et B-tree pour l'égalité exacte ?**
L'index Hash et B-Tree ont des performances similaires pour les recherches par égalité exacte.
Dans certains cas, l'index Hash peut être légèrement plus rapide.

**Pourquoi l'index Hash ne fonctionne-t-il pas pour les recherches par plage ?**
L'index Hash ne stocke pas ses clés dans un ordre trié, donc il ne peut pas vérifier une plage de valeur sans devoir lire toute les données.

**Dans quel contexte précis privilégier un index Hash à un B-tree ?**
L'index Hash est préférable dans une requête avec un grand volume de données et une recherche par égalité exacte.

