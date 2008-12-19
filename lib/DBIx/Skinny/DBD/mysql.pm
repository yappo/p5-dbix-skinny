package DBIx::Skinny::DBD::mysql;
use strict;
use warnings;

sub last_insert_id { $_[2]->{mysql_insertid} || $_[2]->{insertid} }

1;

