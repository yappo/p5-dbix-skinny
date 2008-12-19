package DBIx::Skinny::DBD::SQLite;
use strict;
use warnings;

sub last_insert_id { $_[1]->func('last_insert_rowid') }

1;

