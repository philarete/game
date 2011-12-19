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

# create a Room
$old_counter = $Game::counter; # save counter state
my $room1 = Game::Room->new(description => 'room 1');
isa_ok($room1, 'Game::Room');
isa_ok($room1, 'Game::Object');
ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($Game::objects{ $room1->{id} } eq $room1, 'added to %objects');
ok($room1->describe() eq 'room 1', 'description was correctly set');

$game->save_all();

# save the id so we can reload it later
my $gameid = $Game::gameid;
my $roomid = $room1->{ id };

# allow us to create a new Game
undef($Game::gameid);
undef($Game::dbh);
$Game::counter = 0;
%Game::objects = ();
undef($game);
undef($room1);

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
$game->{description} = 'modified test game';
$game->save();

# load the saved Room from the database
$room1 = Game::Room->load($roomid);
isa_ok($room1, 'Game::Room');
isa_ok($room1, 'Game::Object');
#ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($Game::objects{ $room1->{id} } eq $room1, 'added to %objects');
ok($room1->describe() eq 'room 1', 'description was correctly set');

# change description of room
#$room1->{description} = 'modified room 1';
#$room1->save();
