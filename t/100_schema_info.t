use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock::Basic->setup_test_db;
    };
    test 'schema info' => run {
        is +Mock::Basic->schema, 'Mock::Basic::Schema';

        my $info = Mock::Basic->schema->schema_info;
        is_deeply $info,{
            mock_basic => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            }
        };

        isa_ok +Mock::Basic->dbh, 'DBI::db';
    };
};

