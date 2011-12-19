use 5.012;
use DBI;
use Carp;

# our base class for common methods
package Game::Object;
#use overload '""' => \&Game::Object::describe, fallback => 1;

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
   my $sth = $Game::dbh->prepare($sql);
   $sth->execute($id, $Game::gameid);
   my $data = $sth->fetchrow_hashref;

   # die if an object with that id already exists
   if (exists $Game::objects{id}) {
      Carp::croak "object with id $id already exists";
   }

   # update $Game::counter if necessary
   if ($id >= $Game::counter) {
      $Game::counter = $id + 1;
   }

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
}

sub save_all {
   foreach my $obj (values %Game::objects) {
      $obj->save();
   }
}
      

sub describe {
   my ($self) = @_;
   return $self->{description};
}

package Game;

our @ISA = 'Game::Object';
our $gameid;
our $dbh;
our $counter = 0; # to give every Game::Object a unique id
our %objects = (); # hash of all Game::Object objects
our @saveable = qw(description); # parameters saved by save() method

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
   my $sql = 'insert into Game (id) values (0)';
   $dbh->do($sql);
   $Game::gameid = $dbh->last_insert_id('', '', '', '');
   return $class->SUPER::new(description => $description);
}

sub load {
   Carp::croak "There can only be one Game" if defined($Game::gameid);
   my ($class, $db, $gameid) = @_;
   $Game::gameid = $gameid;
   $Game::dbh = _dbh($db); # set the package variable
   return $class->SUPER::load(0, 'description');
}

package Game::Room;

our @ISA = 'Game::Object';
our @saveable = qw(description); # parameters saved by save() method

# return a true value
1;
