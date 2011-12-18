CREATE TABLE Game (gameid integer primary key, 
                   id integer default 0, -- should always be zero
                   description text);
CREATE TABLE Room (id integer, 
                   gameid integer references Game(id),
                   description text,
                   primary key (id, gameid));
CREATE TABLE north_south ( north integer unique,
                           south integer unique );
CREATE TABLE east_west ( east integer unique,
                         west integer unique );
                           
