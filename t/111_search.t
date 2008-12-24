use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'search test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'search' => run {
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';
    };
};

