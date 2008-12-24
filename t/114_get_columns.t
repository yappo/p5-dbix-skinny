use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'get_columns test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'get_columns' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';

        my $data = $row->get_columns;
        ok $data;
        is $data->{id}, 1;
        is $data->{name}, 'perl';
    };
};

