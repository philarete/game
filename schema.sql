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
                   monster integer,
                   primary key (id, gameid));
CREATE TABLE Character (id integer not null, 
                        gameid integer references Game(gameid),
                        description text,
                        location integer,
                        hp integer, -- hit points
                        damage integer, -- damage when attacking
                        primary key (id, gameid));
CREATE TABLE Monster (id integer not null, 
                      gameid integer references Game(gameid),
                      description text,
                      location integer,
                      hp integer, -- hit points
                      damage integer, -- damage when attacking
                      primary key (id, gameid));
