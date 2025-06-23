# Exercice 6: Synthèse et réflexion
Répondez aux questions suivantes:
1. Quand un index est-il le plus efficace?

○ Pour les recherches ponctuelles ou volumineuses? => Recherches ponctuelles
○ Pour les colonnes avec forte ou faible cardinalité? => forte cardinalité
○ Pour les opérations de type égalité ou intervalle? => plus pour l'égalité un peu pour intervalle court
2. Quels algorithmes de jointure avez-vous observés?
=>
Nested Loop -> petible table + index sur les colonnes de jointures
Hash Join -> grand table (volume), pas trié et pas d'index utilisable
Merge Join -> données triées 
3. Quand le parallélisme est-il activé? => Quand le volume de data est jugé trop important par Postgres
○ Quels types d'opérations en bénéficient le plus? => Les scans, agregation et jointures
○ Pourquoi n'est-il pas toujours utilisé? => faible données à traiter, 
4. Quels types d'index utiliser dans les cas suivants:
○ Recherche exacte sur une colonne => B-tree
○ Filtrage sur plusieurs colonnes combinées => un autre type de B-tree B-tree composite
○ Tri fréquent sur une colonne => B-tree 
○ Jointures fréquentes entre tables => B-tree sur une clé étrangère 

🥳​🥳​🥳​