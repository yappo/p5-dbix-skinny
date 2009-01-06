use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'update test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'update mock_basic data' => run {
        my $row = Mock::Basic->update('mock_basic',{name => 'python'},{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'python';
    };

    test 'row object update' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->name, 'python';

        $row = $row->update({name => 'perl'});
        is $row->name, 'perl';
    };
};

