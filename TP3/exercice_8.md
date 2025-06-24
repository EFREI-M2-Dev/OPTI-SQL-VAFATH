# 8 - Indexation de données JSON/JSONB

## 8.1 Préparation
``` sql
CREATE TABLE film_json (
    tconst TEXT PRIMARY KEY,
    data JSONB
);
```

Exemple d'insert : 

``` sql
INSERT INTO film_json (tconst, data)
VALUES (
    'tt0111161',
    '{
        "primary_title": "The Shawshank Redemption",
        "original_title": "The Shawshank Redemption",
        "start_year": 1994,
        "runtime_minutes": 142,
        "genres": ["Drama"],
        "rating": {
            "average": 9.3,
            "votes": 2500000
        },
        "crew": {
            "directors": ["nm0001104"],
            "writers": ["nm0000175"]
        }
    }'::jsonb
);
```

## 8.2 Requêtes sur données JSON

1. Filtrent sur une propriété de premier niveau
``` sql
SELECT *
FROM film_json
WHERE data ->> 'start_year' = '1994';
```

2. Filtrent sur une propriété imbriquée
``` sql
SELECT *
FROM film_json
WHERE (data -> 'rating' ->> 'average')::numeric >= 9;
```

3. Vérifient l'existence d'une clé
``` sql
SELECT *
FROM film_json
WHERE data ? 'crew';
```

## 8.3 Index sur JSONB
1. Index GIN standard
``` sql
CREATE INDEX idx_film_json_data_gin
ON film_json
USING GIN (data);
```

2. Index GIN avec jsonb_path_ops
``` sql
CREATE INDEX idx_film_json_data_path_ops
ON film_json
USING GIN (data jsonb_path_ops);
```

3. Index B-tree sur une propriété extraite
``` sql
CREATE INDEX idx_film_json_start_year
ON film_json ((data ->> 'start_year'));
```

## 8.4 Analyse et réflexion
1. Quels types d'opérations bénéficient le plus des index GIN sur JSONB?
> Les recherches de présence de clé "?" ou de sous-structure "@>" sont les plus accélérées par les index GIN.

2. Quand utiliser jsonb_path_ops plutôt que l'index GIN standard?
> Quand on fait surtout des recherches avec "@>" et qu’on veut un index plus léger et plus rapide

3. Comment indexer efficacement une propriété spécifique dans une structure JSONB complexe?
> En créant un index B-tree sur l'extraction de la propriété avec "((data ->> 'clé'))"
