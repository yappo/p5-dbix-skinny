package Skinny;
use strict;
use warnings;
use base 'DBIx::Skinny';

__PACKAGE__->setup(
    dsn      => "dbi:SQLite:",
    username => '',
    password => '',
);

1;

