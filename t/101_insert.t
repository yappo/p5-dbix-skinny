use strict;
use warnings;
use utf8;
use Test::Declare;
use YAML;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'insert test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'insert mock_basic data/ insert method' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';
    };

    test 'insert mock_basic data/ create method' => run {
        my $row = Mock::Basic->create('mock_basic',{
            id   => 2,
            name => 'ruby',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'ruby';
    };

    cleanup {
        if ( $ENV{SKINNY_PROFILE} ) {
            warn "query log";
            warn YAML::Dump(Mock::Basic->profiler->query_log);
        }
    };
};

