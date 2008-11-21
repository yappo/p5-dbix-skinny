package DBIx::Skinny::DBD;
use strict;
use warnings;
use UNIVERSAL::require;

sub new {
    my ($class, $dbd_type) =@_;
    die "No Driver" unless $dbd_type;

    my $subclass = join '::', $class, $dbd_type;

    $subclass->use or die $@;

    bless {}, $subclass;
}

1;

