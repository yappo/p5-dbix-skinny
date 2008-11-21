package Skinny::Job;
use strict;
use warnings;
use base 'DBIx::Skinny::Table';

use DateTime;
use DateTime::Format::Strptime;

__PACKAGE__->pk('id');
__PACKAGE__->add_columns(qw/
    id
    name
    created_on
/);
__PACKAGE__->utf8_columns(qw/name/);

__PACKAGE__->add_trigger(pre_insert => sub {
    my ($class, $args) = @_;
    $args->{created_on} = DateTime->now;
});

__PACKAGE__->inflate_column(created_on => {
    inflate => sub {
        my $value = shift;
        my $dt = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d',
        )->parse_datetime($value);
        return DateTime->from_object( object => $dt );
    },
});

1;

