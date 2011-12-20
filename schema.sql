CREATE TABLE Game (gameid integer primary key, 
                   id integer not null, -- should always be zero
                   description text,
                   counter integer not null);
CREATE TABLE Room (id integer not null, 
                   gameid integer references Game(gameid),
                   description text,
                   north integer,
                   south integer,
                   east integer,
                   west integer,
                   primary key (id, gameid));
