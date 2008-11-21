package DBIx::Skinny::DBD::SQLite;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD';

sub last_insert_id { $_[1]->func('last_insert_rowid') }

1;

