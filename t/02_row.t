use strict;
use warnings;
use utf8;
use Test::Declare;
use lib './t';
use Mock;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock->setup_test_db;
        Mock->insert('tag',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'update/delete error: table name typo' => run {
        my $row = Mock->single('tag',{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';

        dies_ok( sub { $row->update('tagg',{name => 'python'})} );
        throws_ok(sub { $row->update('tagg',{name => 'python'}) }, qr/unknown table: tagg/);

        dies_ok(sub { $row->delete('tagg') });
        throws_ok(sub { $row->delete('tagg') }, qr/unknown table: tagg/);
    };

    test 'update/delete error: table have no pk' => run {
        Mock->schema->schema_info->{tag}->{pk} = undef;

        my $row = Mock->single('tag',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';

        dies_ok( sub { $row->update('tag',{name => 'python'})} );
        throws_ok(sub { $row->update('tag',{name => 'python'}) }, qr/tag have no pk./);

        dies_ok( sub { $row->delete('tag')} );
        throws_ok(sub { $row->delete('tag') }, qr/tag have no pk./);

        Mock->schema->schema_info->{tag}->{pk} = 'id';
    };

    test 'update/delete error: select column have no pk.' => run {
        my $row = Mock->search_by_sql(q{SELECT name FROM tag})->first;

        isa_ok $row, 'DBIx::Skinny::Row';

        dies_ok( sub { $row->update('tag',{name => 'python'})} );
        throws_ok(sub { $row->update('tag',{name => 'python'}) }, qr/can't get primary column in your query./);

        dies_ok( sub { $row->delete('tag')} );
        throws_ok(sub { $row->delete('tag') }, qr/can't get primary column in your query./);
    };
};

