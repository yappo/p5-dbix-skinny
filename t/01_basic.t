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

    test 'insert mock_basic data' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
    };

    test 'update mock_basic data' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';

        $row = Mock::Basic->update('mock_basic',{name => 'python'},{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'python';
    };

    test 'delete mock_basic data' => run {
        Mock::Basic->delete('mock_basic',{id => 1});
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        ok ! $row;
    };

    test 'search' => run {
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });

        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id , 1;
        is $row->name, 'perl';

        my $data = $row->get_columns;
        ok $data;
        is $data->{id} , 1;
        is $data->{name}, 'perl';
    };

    test 'search_by_sql' => run {
        my $itr = Mock::Basic->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, 1);
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';

        my $data = $row->get_columns;
        ok $data;
        is $data->{id} , 1;
        is $data->{name}, 'perl';
    };

    test 'resultset' => run {
        my $rs = Mock::Basic->resultset;
        isa_ok $rs, 'DBIx::Skinny::SQL';

        $rs->add_select('name');
        $rs->from(['mock_basic']);
        $rs->add_where(id => 1);
        my $itr = $rs->retrieve;
        
        isa_ok $itr, 'DBIx::Skinny::Iterator';
    
        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
    
        is $row->name, 'perl';

        my $data = $row->get_columns;
        ok $data;
        is $data->{name}, 'perl';
    };

    test 'row update/delete' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->name, 'perl';

        $row = $row->update('mock_basic',{name => 'python'});
        is $row->name, 'python';

        $row->delete('mock_basic');
        $row = Mock::Basic->single('mock_basic',{id => 1});
        ok !$row;
    };
};

