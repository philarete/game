use 5.012;
use Test::More;

BEGIN { use_ok('Game'); }

# create a new Game
my $old_counter = $Game::counter; # save counter state
my $game = Game->new('TEST.db', 'test game');
ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($Game::objects{ $game->{id} } eq $game, 'added to %objects');
isa_ok($game, 'Game');
isa_ok($game, 'Game::Object');
ok(defined $Game::gameid, '$Game::gameid is defined after new()');
isa_ok($Game::dbh, 'DBI::db');

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
ok(sprintf('%s', $game) eq $game->describe(), 'stringification is overloaded');

# save the id for future use
my $saved_id = $Game::gameid;

# allow us to create a new Game
undef($Game::gameid);
undef($Game::dbh);
$Game::counter = 0;
%Game::objects = ();
undef($game);

# load the same Game from the database
$old_counter = $Game::counter; # save counter state
$game = Game->load('TEST.db', $saved_id);
#ok($Game::counter == $old_counter + 1, 'counter was incremented');
isa_ok($game, 'Game');
isa_ok($game, 'Game::Object');
ok(defined $Game::gameid, '$Game::id is defined after load()');
isa_ok($Game::dbh, 'DBI::db');

# postpone further tests
#exit 0;

# describe() method
ok($game->describe() eq 'test game', 'description set after load()');

# create a Room
$old_counter = $Game::counter; # save counter state
my $room1 = Game::Room->new(description => 'room 1');
isa_ok($room1, 'Game::Room');
isa_ok($room1, 'Game::Object');
ok($Game::counter == $old_counter + 1, 'counter was incremented');
ok($Game::objects{ $room1->{id} } eq $room1, 'added to %objects');
ok($room1 eq 'room 1', 'description was correctly set');

$room1->save('description');
