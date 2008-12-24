use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Inflate;
use Mock::Inflate::Name;

plan tests => blocks;

describe 'inflate/deflate test' => run {
    init {
        Mock::Inflate->setup_test_db;
    };

    test 'schema info' => run {
        is +Mock::Inflate->schema, 'Mock::Inflate::Schema';

        my $info = Mock::Inflate->schema->schema_info;
        is_deeply $info,{
            mock_inflate => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            }
        };
        ## TODO: inflate info
        isa_ok +Mock::Inflate->dbh, 'DBI::db';
    };

    test 'insert mock_inflate data' => run {
        my $name = Mock::Inflate::Name->new(name => 'perl');

        my $row = Mock::Inflate->insert('mock_inflate',{
            id   => 1,
            name => $name,
        });

        isa_ok $row, 'DBIx::Skinny::Row';
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name, 'perl';
    };

    test 'update mock_inflate data' => run {
        my $name = Mock::Inflate::Name->new(name => 'ruby');

        my $row = Mock::Inflate->update('mock_inflate',{name => $name},{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name, 'ruby';
    };
};

