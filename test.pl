use 5.012;
use Test::More;

BEGIN { use_ok('Game'); }

# create a new Game
my $old_counter = $Game::counter; # save counter state
my $game = Game->new('TEST.db', 'test game');
isa_ok($game, 'Game');
isa_ok($game, 'Game::Object');
isa_ok($Game::dbh, 'DBI::db');
ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($game->{id} eq '0', 'id field is 0');
ok($Game::objects{ $game->{id} } eq $game, 'added to %objects');
ok(defined $Game::gameid, '$Game::gameid is defined after new()');

# foreign_keys pragma should be set
my $sth = $Game::dbh->prepare('pragma foreign_keys');
$sth->execute;
my ($rv) = $sth->fetchrow;
ok($rv == 1, 'pragma foreign keys is on');

# throw error if you try to have more than one Game
eval{ my $game2 = Game->new(); };
chomp $@;
ok($@, $@);
eval { my $game2 = Game->load(); };
chomp $@;
ok($@, $@);

# describe() method
ok($game->describe() eq 'test game', 'description set after new()');

# stringification should be overloaded
#ok(sprintf('%s', $game) eq $game->describe(), 'stringification is overloaded');

# create two Rooms
$old_counter = $Game::counter; # save counter state
my $room1 = Game::Room->new(description => 'room 1');
isa_ok($room1, 'Game::Room');
isa_ok($room1, 'Game::Object');
ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($Game::objects{ $room1->{id} } eq $room1, 'added to %objects');
ok($room1->describe() eq 'room 1', 'description was correctly set');

my $room2 = Game::Room->new(description => 'room 2');
my $room3 = Game::Room->new(description => 'room 3');

$room1->set_north($room2);
$room2->set_east($room3);

ok($room1->north eq $room2, 'room2 is to the north of room1');
ok($room2->south eq $room1, 'room1 is to the south of room2');
ok($room2->east eq $room3, 'room3 is to the east of room2');
ok($room3->west eq $room2, 'room2 is to the west of room3');

say "Room 1 exits: ", join(', ', $room1->exits);
say "Room 2 exits: ", join(', ', $room2->exits);
say "Room 3 exits: ", join(', ', $room3->exits);

# create a character
my $pc = Game::Character->new(description => 'Brave Sir Robin',
                              hp => 10, damage => 4);
isa_ok($pc, 'Game::Character');                           
$pc->set_location($room1); # start in room 1
ok($pc->location eq $room1, 'Sir Robin starts in room 1');

$pc->go_north; # go north to room 2
ok($pc->location eq $room2, 'Sir Robin moves north to room 2');

$pc->go_east; # go east to room 3
ok($pc->location eq $room3, 'Sir Robin moves east to room 3');

# create a monster
my $monster = Game::Monster->new(description => 'Three-headed Giant',
                                 hp => 10, damage => 4);
$monster->set_location($room3);
isa_ok($monster, 'Game::Monster');
ok($monster->location eq $room3, 'Three-headed Giant has location room3');
ok($room3->monster eq $monster, 'Room 3 has monster Three-headed Giant');

# save hp for comparison after attacks
my $pc_original_hp = $pc->hp;
my $monster_original_hp = $monster->hp;

$pc->attack($monster);
$monster->attack($pc);

ok($pc->hp < $pc_original_hp, 'Sir Robin has fewer hp after attack');
say "Sir Robin's hp: ", $pc->hp;
ok($monster->hp < $monster_original_hp, 'Three-headed Giant has fewer hp after attack');
say "Three-headed Giant's hp: ", $monster->hp;

$game->save_all();

# save the id so we can reload it later
my $gameid = $Game::gameid;
#say "gameid is $gameid";
#my $room1id = $room1->id;
#say "room1id is $room1id";
#my $room2id = $room2->id;
#say "room2id is $room2id";
#my $room3id = $room3->id;
#say "room3id is $room3id";
#my $pc_id = $pc->id;
#say "pc_id is $pc_id";
#my $monster_id = $monster->id;
#say "monster_id is $monster_id";

# clear all
undef($Game::gameid);
undef($Game::dbh);
$Game::counter = 0;
%Game::objects = ();
undef($game);
undef($room1);
undef($room2);
undef($room3);
undef($pc);
undef($monster);

# load the saved Game from the database
$old_counter = $Game::counter; # save counter state
$game = Game->load('TEST.db', $gameid);
#ok($Game::counter == $old_counter + 1, 'counter was incremented');
isa_ok($game, 'Game');
isa_ok($game, 'Game::Object');
isa_ok($Game::dbh, 'DBI::db');
ok($game->{id} eq '0', 'id field is 0');
ok(defined $Game::gameid, '$Game::id is defined after load()');

# describe() method
ok($game->describe() eq 'test game', 'description set after load()');

# change description of game
#$game->{description} = 'modified test game';

# load the saved Rooms from the database
$game->load_all;

my ($room1, $room2, $room3) = 
   sort { $a->describe cmp $b->describe } $game->list_of('Room');

#say $game->list_of('Room');

# postpone further tests
#exit 0;

#$room1 = $Game::objects{$room1id};
isa_ok($room1, 'Game::Room');
ok($room1->describe() eq 'room 1', 'room1 description was correctly set');

#$room2 = $Game::objects{$room2id};
isa_ok($room2, 'Game::Room');
ok($room2->describe() eq 'room 2', 'room2 description was correctly set');

#$room3 = $Game::objects{$room3id};
isa_ok($room3, 'Game::Room');
ok($room3->describe() eq 'room 3', 'room3 description was correctly set');

ok($room1->north eq $room2, 'room2 is to the north of room1');
ok($room2->south eq $room1, 'room1 is to the south of room2');
ok($room2->east eq $room3, 'room3 is to the east of room2');
ok($room3->west eq $room2, 'room2 is to the west of room3');

($pc) = $game->list_of('Character');
#$pc = $Game::objects{$pc_id};
#say "PC is ", $pc->describe;
isa_ok($pc, 'Game::Character');
ok($pc->location eq $room3, "$pc is still in room 3");

($monster) = $game->list_of('Monster');
#$monster = $Game::objects{$monster_id};
#say "Monster is ", $monster->describe;
isa_ok($monster, 'Game::Monster');
ok($monster->location eq $room3, "$monster is still in room 3");
