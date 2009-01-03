use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;
use Mock::BasicMySQL;

plan tests => blocks;

describe 'insert test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::BasicMySQL->setup_test_db;
    };

    test 'bulk_insert method' => run {
        Mock::Basic->bulk_insert('mock_basic',[
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);
        is +Mock::Basic->count('mock_basic',{count => 'id'})->count, 3;

        Mock::BasicMySQL->bulk_insert('mock_basic_mysql',[
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);
        is +Mock::BasicMySQL->count('mock_basic_mysql',{count => 'id'})->count, 3;
    };
    cleanup {
        Mock::BasicMySQL->cleanup_test_db;
    };
};

