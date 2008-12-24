use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::UTF8;

plan tests => blocks;

describe 'utf8 test' => run {
    init {
        Mock::UTF8->setup_test_db;
    };

    test 'schema info' => run {
        is +Mock::UTF8->schema, 'Mock::UTF8::Schema';

        my $info = Mock::UTF8->schema->schema_info;
        is_deeply $info,{
            mock_utf8 => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            }
        };
        isa_ok +Mock::UTF8->dbh, 'DBI::db';
    };

    test 'insert mock_utf8 data' => run {
        my $row = Mock::UTF8->insert('mock_utf8',{
            id   => 1,
            name => 'ぱーる',
        });

        isa_ok $row, 'DBIx::Skinny::Row';
        ok utf8::is_utf8($row->name);
        is $row->name, 'ぱーる';
    };

    test 'update mock_utf8 data' => run {
        my $row = Mock::UTF8->update('mock_utf8',{name => 'るびー'},{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        ok utf8::is_utf8($row->name);
        is $row->name, 'るびー';
    };
};

