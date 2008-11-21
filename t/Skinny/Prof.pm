package Skinny::Prof;
use strict;
use warnings;
use base 'DBIx::Skinny::Table';

use DateTime;
use DateTime::Format::Strptime;

__PACKAGE__->pk('id');
__PACKAGE__->add_columns(qw/
    id
    user_id
    mail
    date
/);

__PACKAGE__->inflate_column(date => {
    inflate => sub {
        my $value = shift;
        my $dt = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d',
        )->parse_datetime($value);
        return DateTime->from_object( object => $dt );
    },
});

1;

