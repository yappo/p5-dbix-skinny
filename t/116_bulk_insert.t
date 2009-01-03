use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'insert test' => run {
    init {
        Mock::Basic->setup_test_db;
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
    };
};

