CREATE TABLE Game (gameid integer primary key, 
                   id integer default 0, -- should always be zero
                   description text);
CREATE TABLE Room (id integer, 
                   gameid integer references Game(id),
                   description text,
                   primary key (id, gameid));
