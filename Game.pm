use 5.012;
use DBI;
use Carp;

# our base class for common methods
package Game::Object;
use overload '""' => \&Game::Object::describe, fallback => 1;

sub new {

   my $class = shift;
   my $id = $Game::counter++; # get counter, then increment

   # die if an object with that id already exists
   if (exists $Game::objects{id}) {
      Carp::croak "object with id $id already exists";
   }

   # add to %Game::objects and return
   return $Game::objects{$id} = bless { @_, id => $id  }, $class;
}

# load an existing object from the database
# parameters: object id
sub load {

   my $class = shift;
   my $id = shift;

   # portion of class name after final ::
   my $table = (split('::', $class))[-1];

   no strict 'refs'; # need to access @saveable symbolically
   my @saveable = @{ $class . '::saveable' };

   # get the data from the database
   my @quoted = map { $Game::dbh->quote_identifier($_) } @saveable, 'id';
   my $quoted = join ', ', @quoted;
   my $sql = "select $quoted from $table where id = ? and gameid = ?";
   # Carp::carp $sql;
   my $sth = $Game::dbh->prepare($sql);
   $sth->execute($id, $Game::gameid);
   my $data = $sth->fetchrow_hashref;

   return if !$data;

   # die if an object with that id already exists
   if (exists $Game::objects{id}) {
      Carp::croak "object with id $id already exists";
   }

   # Carp::carp "Blessing object $id as $class";
   return $Game::objects{$id} = bless $data, $class;
}

# parameters - fields to be saved to database
sub save {
   my $self = shift;
   my $class = ref($self);

   no strict 'refs'; # need to access @saveable symbolically
   my @saveable = @{ $class . '::saveable' };

   # construct lists for update and insert sql
   my ($k, $v, @fields, @values);
   foreach (@saveable, 'id', 'gameid') {
      my ($k, $v);

      $k = $Game::dbh->quote_identifier($_);

      if ($_ eq 'gameid') {
         $v = $Game::dbh->quote( $Game::gameid );
      } else {
         $v = $Game::dbh->quote( $self->{$_} );
      }

      push @fields, $k;
      push @values, $v;
   }

   # portion of class name after final ::
   my $table = ( split( '::', ref($self) ) )[-1];
   # join lists
   my $fields = join(', ', @fields);
   my $values = join(', ', @values);

   my $sql = "insert or replace into $table ($fields) values ($values)";
   #Carp::carp $sql;

   $Game::dbh->do($sql);

   return $self;
}

sub save_all {
   my $self = shift;
   foreach my $obj (values %Game::objects) {
      $obj->save();
   }
   return $self;
}

sub id {
   my $self = shift;
   return $self->{id};
}

sub describe {
   my $self = shift;
   return $self->{description};
}

package Game;

our @ISA = 'Game::Object';

# package variables
our $gameid; # unique id for each game
our $dbh; # database handle to sqlite
our $counter = 0; # to give every Game::Object a unique id
our %objects = (); # hash of all Game::Object objects
our @saveable = qw(description counter); # parameters saved by save() method

# not a method
sub _dbh {
   my $db = shift;
   my $dsn = "DBI:SQLite:dbname=$db";
   my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
   $dbh->do('pragma foreign_keys = on'); # enforce referential constraints
   return $dbh;
}

sub new {
   Carp::croak "There can only be one Game" if defined($Game::gameid);
   my ($class, $db, $description) = @_;
   $Game::dbh = _dbh($db); # set the package variable
   my $sql = 'insert into Game (id, counter) values (0, 0)';
   $dbh->do($sql);
   $Game::gameid = $dbh->last_insert_id('', '', '', '');
   return $class->SUPER::new(description => $description);
}

sub save {
   my $self = shift;
   # set counter field so it is saved
   $self->{counter} = $Game::counter;
   return $self->SUPER::save();
}

sub load {
   Carp::croak "There can only be one Game" if defined($Game::gameid);
   my ($class, $db, $gameid) = @_;
   $Game::gameid = $gameid;
   $Game::dbh = _dbh($db); # set the package variable
   my $game = $class->SUPER::load(0, 'description');
   $Game::counter = $game->{counter}; # set the package counter
   return $game;
}

sub load_all {
   my $self = shift;
   my @classes = qw( Game::Room Game::Character Game::Monster );
   my $sql_template = 'select id from %s where gameid = ?';

   foreach my $class (@classes) {
      my $table = (split('::', $class))[-1];
      my $sql = sprintf($sql_template, $Game::dbh->quote_identifier($table));
      my $sth = $Game::dbh->prepare($sql);
      $sth->execute($Game::gameid);
      while (my ($id) = $sth->fetchrow) {
         $class->load($id);
      }
   }
   return $self;
}

# list of all Game::Objects of a given class
# in no particular order
sub list_of {
   my ($self, $class) = @_;
   $class = 'Game::' . $class; 
   my @rv;
   foreach my $obj (values %Game::objects) {
      if (ref($obj) eq $class) {
        push @rv, $obj;
     }
   }
   return @rv;
}

package Game::Room;

our @ISA = 'Game::Object';
# parameters saved by save() method
our @saveable = qw(description north south east west monster); 

sub north {
   my $self = shift;
   return $Game::objects{ $self->{north} };
}

sub south {
   my $self = shift;
   return $Game::objects{ $self->{south} };
}

sub east {
   my $self = shift;
   return $Game::objects{ $self->{east} };
}

sub west {
   my $self = shift;
   return $Game::objects{ $self->{west} };
}

# list of available exits
sub exits {
   my $self = shift;
   my @rv;
   push @rv, 'north' if $self->north;
   push @rv, 'south' if $self->south;
   push @rv, 'east'  if $self->east;
   push @rv, 'west'  if $self->west;
   return @rv;
}

sub monster {
   my $self = shift;
   return $Game::objects{ $self->{monster} };
}

sub set_north {
   my ($self, $north) = @_;
   $self->{north} = $north->id;
   $north->{south} = $self->id;
   return $self;
}

sub set_south {
   my ($self, $south) = @_;
   $self->{south} = $south->id;
   $south->{north} = $self->id;
   return $self;
}

sub set_east {
   my ($self, $east) = @_;
   $self->{east} = $east->id;
   $east->{west} = $self->id;
   return $self;
}

sub set_west {
   my ($self, $west) = @_;
   $self->{west} = $west->id;
   $west->{east} = $self->id;
   return $self;
}

sub set_monster {
   my ($self, $monster) = @_;
   $self->{monster} = $monster->id;
   $monster->{location} = $self->id;
   return $self;
}

# superclass for Character and Monster
package Game::LivingThing;

our @ISA = 'Game::Object';

# should be implemented by subclasses
sub set_location {
   ...
}

sub location {
   my $self = shift;
   return $Game::objects{ $self->{location} };
}

sub go_north {
   my $self = shift;
   $self->set_location( $self->location->north );
   return $self;
}

sub go_south {
   my $self = shift;
   $self->set_location( $self->location->south );
   return $self;
}

sub go_east {
   my $self = shift;
   $self->set_location( $self->location->east );
   return $self;
}

sub go_west {
   my $self = shift;
   $self->set_location( $self->location->west );
   return $self;
}

sub hp {
   my $self = shift;
   return $self->{hp};
}

sub set_hp {
   my ($self, $new_hp) = @_;
   $self->{hp} = $new_hp;
   return $self;
}

# random damage
sub get_damage {
   my $self = shift;
   return int(rand($self->{damage})) + 1;
}

sub attack {
   my ($self, $target) = @_;
   my $damage = $self->get_damage;
   #Carp::carp "Attack does $damage points of damage.";
   $target->set_hp( $target->hp - $damage );
   return $damage;
}

package Game::Monster;

our @ISA = 'Game::LivingThing';
our @saveable = qw(description hp location damage);

sub set_location {
   my ($self, $location) = @_;
   $self->{location} = $location->id;
   $location->{monster} = $self->id;
   return $self;
}

package Game::Character;

our @ISA = 'Game::LivingThing';
our @saveable = qw(description hp location damage);

sub set_location {
   my ($self, $location) = @_;
   $self->{location} = $location->id;
   return $self;
}

# return a true value
1;
