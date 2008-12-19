use strict;
use warnings;
use Test::Declare;
use lib './t';
use utf8;
use Mock;
use DateTime;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock->setup_test_db;
    };
    test 'schema info' => run {
        is +Mock->schema, 'Mock::Schema';

        my $info = Mock->schema->schema_info;
        is_deeply $info,{
            tag => {
                pk      => 'id',
                columns => [
                    'id',
                    'guid',
                    'name',
                    'created_at',
                ],
                trigger => {
                    pre_insert => $info->{tag}->{trigger}->{pre_insert},
                },
            }
        };

        isa_ok +Mock->dbh, 'DBI::db';
    };

    test 'insert tag data' => run {
        my $row = Mock->insert('tag',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        ok $row->guid;
        isa_ok $row->created_at, 'DateTime';
    };

    test 'update tag data' => run {
        my $row = Mock->single('tag',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';

        $row = Mock->update('tag',{name => 'python'},{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'python';

        $row = Mock->update('tag', {created_at => DateTime->new(
            year => 2008, month => 1, day => 2, hour => 3, minute => 4, second => 5,
        )},{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->created_at, '2008-01-02T03:04:05';
    };

    test 'delete tag data' => run {
        Mock->delete('tag',{id => 1});
        my $row = Mock->single('tag',{id => 1});
        ok ! $row;
    };

    test 'search' => run {
        Mock->insert('tag',{
            id   => 1,
            name => 'perl',
        });

        my $itr = Mock->search('tag',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        isa_ok $row->created_at, 'DateTime';
        ok $row->guid;
        is $row->id , 1;
        is $row->name, 'perl';

        my $data = $row->get_columns;
        ok $data;
        isa_ok $row->created_at, 'DateTime';
        ok $data->{created_at};
        ok $data->{guid};
        is $data->{id} , 1;
        is $data->{name}, 'perl';
    };

    test 'search_by_sql' => run {
        my $itr = Mock->search_by_sql(q{SELECT * FROM tag WHERE id = ?}, 1);
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        isa_ok $row->created_at, 'DateTime';
        ok $row->guid;
        is $row->id , 1;
        is $row->name, 'perl';

        my $data = $row->get_columns;
        ok $data;
        isa_ok $row->created_at, 'DateTime';
        ok $data->{created_at};
        ok $data->{guid};
        is $data->{id} , 1;
        is $data->{name}, 'perl';
    };

    test 'resultset' => run {
        my $rs = Mock->resultset;
        isa_ok $rs, 'DBIx::Skinny::SQL';
        $rs->add_select('name');
        $rs->from(['tag']);
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

    test 'utf8' => run {
        my $row = Mock->update('tag',{name => 'ぱーる'},{id => 1});        

        ok utf8::is_utf8($row->name);
        is $row->name, 'ぱーる';
    };

    test 'row update/delete' => run {
        my $row = Mock->single('tag',{id => 1});
        is $row->name, 'ぱーる';

        $row = $row->update('tag',{name => 'ぱいそん'});
        is $row->name, 'ぱいそん';

        $row->delete('tag');
        $row = Mock->single('tag',{id => 1});
        ok !$row;
    };
};





