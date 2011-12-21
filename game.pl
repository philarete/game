use 5.012;
use lib '.';
use Game;

my $db = 'TEST.db';
my $prompt = '> ';
my $cant_go_that_way = "You can't go that way.";

my $gameid = shift;

# load existing game or create new one
my $game;
if (defined $gameid) {
   $game = Game->load($db, $gameid);
   $game->load_all;
} else {
   $game = new_game();
}

# get the Character object from $game
my ($pc) = $game->list_of('Character');

look();
while (1) {
  print $prompt;
  my $command = <>;
 
  if ($command =~ /^health/i) {
     my $hp = $pc->hp;
     say "You have $hp hit points.";
  } elsif ($command =~ /^save/i) {
     $game->save_all;
     say "Game saved as ", $Game::gameid, ".";
  } elsif ($command =~ /^h/i) {
     help();
  } elsif ($command =~ /^l/i) {
     look();
  } elsif ($command =~ /^n/i) {
     go_north();
  } elsif ($command =~ /^s/i) {
     go_south();
  } elsif ($command =~ /^e/i) {
     go_east();
  } elsif ($command =~ /^w/i) {
     go_west();
  } elsif ($command =~ /^a/i) {
     attack();
  } elsif ($command =~ /^q/i) {
     $game->save_all;
     say "Game saved as ", $Game::gameid, ".";
     exit 0;
  } else {
     say "I don't understand that command.";
  }
}

sub help {
   say "Available commands:";
   say "help (h)";
   say "north (n)";
   say "south (s)";
   say "east (e)";
   say "west (w)";
   say "attack (a)";
   say "health";
   say "save";
   say "quit (q)";
}

sub look {
   say "You are in ", $pc->location;
   say "Exits are: ", join(', ', $pc->location->exits);
   if ($pc->location->monster) {
      say ucfirst($pc->location->monster), " is here.";
   }
}

sub go_north {
   if ($pc->location->north) {
      $pc->go_north;
      look();
   } else {
      say $cant_go_that_way;
   }
}

sub go_south {
   if ($pc->location->south) {
      $pc->go_south;
      look();
   } else {
      say $cant_go_that_way;
   }
}

sub go_east {
   if ($pc->location->east) {
      $pc->go_east;
      look();
   } else {
      say $cant_go_that_way;
   }
}

sub go_west {
   if ($pc->location->west) {
      $pc->go_west;
      look();
   } else {
      say $cant_go_that_way;
   }
}


sub attack {
   if (my $monster = $pc->location->monster) {
      my $damage = $pc->attack($monster);
      say "You attack $monster, dealing $damage damage.";
      $damage = $monster->attack($pc);
      say ucfirst($monster), " attacks you, dealing $damage damage.";
   } else {
      say "You attack the darkness.";
   }
}

sub new_game {
   my $game = Game->new($db, description => 'the Tale of Sir Robin');
   my $room1 = Game::Room->new(description => 'the entrance');
   my $room2 = Game::Room->new(description => 'the throne room');
   my $room3 = Game::Room->new(description => 'the arena');

   # arrange the rooms
   $room1->set_north($room2);
   $room2->set_east($room3);

   # create the monster
   my $monster = Game::Monster->new(description => 'the Three-headed Giant',
                                    hp => 10, damage => 4);
   $monster->set_location($room3);

   # and our hero
   my $pc = Game::Character->new(description => 'Sir Robin',
                                 hp => 10, damage => 4);
   $pc->set_location($room1);

   return $game;
}
