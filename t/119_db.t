use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::DB;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock::DB->connect_info(
            {
                dsn => 'dbi:SQLite:',
                username => '',
                password => '',
            }
        );
        Mock::DB->setup_test_db;
    };
    test 'dbh info' => run {
        isa_ok +Mock::DB->dbh, 'DBI::db';
    };

    test 'insert' => run {
        Mock::DB->insert('mock_db',{id => 1 ,name => 'nekokak'});
        is +Mock::DB->count('mock_db','id',{name => 'nekokak'}), 1;
    };
};

