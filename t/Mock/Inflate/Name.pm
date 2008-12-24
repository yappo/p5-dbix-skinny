package Mock::Inflate::Name;
use overload '""' => sub { shift->name}, fallback => 1;
sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}
sub name { shift->{name} };
1;
