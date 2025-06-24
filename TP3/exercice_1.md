
# Exercice 1 : Index B-tree


## 1.1 Analyse sans index

Écrivez une requête avec `EXPLAIN ANALYZE` qui recherche dans la table `title_basics` tous les titres commençant par "The" (utilisez `LIKE`).

```sql
EXPLAIN ANALYZE
SELECT *
FROM public.title_basics
WHERE primary_title LIKE 'The%';
````

> ```
> "Gather  (cost=1000.00..299348.06 rows=633730 width=84) (actual time=21.294..829.442 rows=605129 loops=1)"
> "  Workers Planned: 2"
> "  Workers Launched: 2"
> "  ->  Parallel Seq Scan on title_basics  (cost=0.00..234975.06 rows=264054 width=84) (actual time=8.954..795.183 rows=201710 loops=3)"
> "        Filter: ((primary_title)::text ~~ 'The%'::text)"
> "        Rows Removed by Filter: 3709910"
> "Planning Time: 2.498 ms"
> "JIT:"
> "  Functions: 6"
> "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
> "  Timing: Generation 0.762 ms (Deform 0.182 ms), Inlining 0.000 ms, Optimization 2.454 ms, Emission 23.561 ms, Total 26.776 ms"
> "Execution Time: 966.549 ms"
> ```

## 1.2 Création d'un index B-tree

Créez un index B-tree sur la colonne `primary_title` de la table `title_basics`.

```sql
CREATE INDEX idx_title_basics_primary_title
ON public.title_basics (primary_title);
```

> Résultat :
> `CREATE INDEX`
> Query returned successfully in 18 secs 150 msec.


## 1.3 Analyse après indexation

Exécutez à nouveau la même requête qu'en 1.1 et analysez les différences de performance et de plan d'exécution.

```sql
EXPLAIN ANALYZE
SELECT *
FROM public.title_basics
WHERE primary_title LIKE 'The%';
```

> ```
> "Gather  (cost=1000.00..299348.06 rows=633730 width=84) (actual time=2.705..275.436 rows=605129 loops=1)"
> "  Workers Planned: 2"
> "  Workers Launched: 2"
> "  ->  Parallel Seq Scan on title_basics  (cost=0.00..234975.06 rows=264054 width=84) (actual time=2.404..251.434 rows=201710 loops=3)"
> "        Filter: ((primary_title)::text ~~ 'The%'::text)"
> "        Rows Removed by Filter: 3709910"
> "Planning Time: 0.081 ms"
> "JIT:"
> "  Functions: 6"
> "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
> "  Timing: Generation 0.518 ms (Deform 0.204 ms), Inlining 0.000 ms, Optimization 0.470 ms, Emission 6.639 ms, Total 7.627 ms"
> "Execution Time: 288.085 ms"
> ```


## 1.4 Test des différentes opérations

Testez plusieurs types de conditions et notez lesquelles bénéficient de l'index B-tree :

| Type d’opération                                    | Utilisation de l’index B-tree ? |
| --------------------------------------------------- | ------------------------------- |
| 1. Égalité exacte (`WHERE primary_title = '...'`)   | **OUI**                         |
| 2. Préfixe (`WHERE primary_title LIKE 'The%'`)      | **OUI**                         |
| 3. Suffixe (`WHERE primary_title LIKE '%The'`)      | **NON**                         |
| 4. Sous-chaîne (`WHERE primary_title LIKE '%The%'`) | **NON**                         |
| 5. Ordre (`ORDER BY primary_title`)                 | **OUI**                         |

---

## 1.5 Analyse et réflexion

**Répondez aux questions :**

1. **Pour quels types d'opérations l'index B-tree est-il efficace ?**
   Égalité exacte, recherches sur préfixe (`LIKE 'abc%'`), comparaisons d’intervalle, et tris (`ORDER BY`).

2. **Pourquoi l'index n'est-il pas utilisé pour certaines opérations ?**
   Parce que l’ordre des données ne peut pas être exploité, notamment avec des motifs `LIKE` commençant par `%` (wildcard en début).

3. **Dans quels cas un index B-tree est-il le meilleur choix ?**
   Quand on fait des recherches par égalité, par plage, par préfixe, ou quand on trie sur la colonne indexée.


