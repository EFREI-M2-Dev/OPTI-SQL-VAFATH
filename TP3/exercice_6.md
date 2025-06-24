# 6 - Index couvrants (INCLUDE)

## 6.1 Requête fréquente avec projection

Query : 
``` sql
SELECT primary_title, start_year
FROM title_basics
WHERE genres = 'Drama';
```

## 6.2 Index standard

Index : 
``` sql
CREATE INDEX idx_genres_only
ON title_basics (genres);
```

## 6.3 Index couvrant

Index : 
``` sql
CREATE INDEX idx_genres_covering
ON title_basics (genres)
INCLUDE (primary_title, start_year);
```

## 6.4 Comparaison des performances

Comparaison des 3 cas :
| Cas | Type de plan | Index utilisé | Accès au disque (Heap Fetches) | Temps d’accès index | Temps d'exécution total |
| :- | :- | :- | :- | :- | :- |
| Sans index | Bitmap Heap Scan | idx_genres_start_year | Oui (heap blocks + lossy) | 54.793 ms | 22937.222 ms |
| Index standard | Bitmap Heap Scan | idx_genres_only | Oui (heap blocks + lossy) | 32.170 ms | 2353.328 ms |
| Index couvrant | Index Only Scan | idx_genres_covering | Aucun | 0.017 ms | 130.451 ms |


## 6.5 Analyse et réflexion
1. Qu'est-ce qu'un "Index Only Scan" et pourquoi est-il avantageux?7
> Lecture des données de l'index sans acceder à la table.

2. Quelle est la différence entre ajouter une colonne à l'index et l'inclure avec INCLUDE?
> L'ajout simple permet le tri contrairement à l'INCLUDE mais ce derniers est plus rapide pour simplement récuperer les lignes.

3. Quand privilégier un index couvrant par rapport à un index composite?
> Quand il y a un seul filtre mais plusieurs colonnes récuperer sans les filtrer.
