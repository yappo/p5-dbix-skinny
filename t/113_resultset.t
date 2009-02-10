use strict;
use warnings;
use utf8;
use Test::Declare;
use YAML;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'resultset test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
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
    };

    cleanup {
        if ( $ENV{SKINNY_PROFILE} ) {
            warn "query log";
            warn YAML::Dump(Mock::Basic->profiler->query_log);
        }
    };
};

