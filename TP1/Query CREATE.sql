-- title.akas.tsv.gz

CREATE TABLE title_akas (
title_id VARCHAR(12),
ordering INTEGER,
title VARCHAR(1000),
region VARCHAR(10),
language VARCHAR(20),
types VARCHAR(200),
attributes VARCHAR(200),
is_original_title BOOLEAN,
PRIMARY KEY (title_id, ordering)
);

COPY title_akas FROM PROGRAM 'zcat /import/title.akas.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001');

-- title.crew.tsv.gz

CREATE TABLE title_crew (
tconst VARCHAR(12) PRIMARY KEY,
directors TEXT,
writers TEXT
);

COPY title_crew FROM PROGRAM 'zcat /import/title.crew.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001');

-- title.episode.tsv.gz

CREATE TABLE title_episode (
tconst VARCHAR(12) PRIMARY KEY,
parent_tconst VARCHAR(12),
season_number INTEGER,
episode_number INTEGER
);

COPY title_episode FROM PROGRAM 'zcat /import/title.episode.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001');

-- title.principals.tsv.gz

CREATE TABLE title_principals (
tconst VARCHAR(12),
ordering INTEGER,
nconst VARCHAR(12),
category VARCHAR(100),
job TEXT,
characters TEXT,
PRIMARY KEY (tconst, ordering)
);

COPY title_principals FROM PROGRAM 'zcat /import/title.principals.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001'); 

-- title.ratings.tsv.gz

CREATE TABLE title_ratings (
tconst VARCHAR(12) PRIMARY KEY,
average_rating NUMERIC(3,1),
num_votes INTEGER
);

COPY title_ratings FROM PROGRAM 'zcat /import/title.ratings.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001');

-- name.basics.tsv.gz

CREATE TABLE name_basics (
nconst VARCHAR(12) PRIMARY KEY,
primary_name VARCHAR(200),
birth_year INTEGER,
death_year INTEGER,
primary_profession TEXT,
known_for_titles TEXT
);

COPY name_basics FROM PROGRAM 'zcat /import/name.basics.tsv.gz'
WITH (FORMAT csv,DELIMITER E'\t',HEADER,NULL '\N',QUOTE E'\001');
