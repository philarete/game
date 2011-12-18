CREATE TABLE Game (gameid integer primary key, 
                   id integer not null, -- should always be zero
                   description text);
CREATE TABLE Room (id integer not null, 
                   gameid integer references Game(gameid),
                   description text,
                   primary key (id, gameid));
CREATE TABLE north_south ( north integer unique,
                           south integer unique );
CREATE TABLE east_west ( east integer unique,
                         west integer unique );
                           
