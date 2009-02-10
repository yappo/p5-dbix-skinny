use strict;
use warnings;
use utf8;
use Test::Declare;
use YAML;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'single test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'single' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->id, 1;
        is $row->name, 'perl';
    };

    cleanup {
        if ( $ENV{SKINNY_PROFILE} ) {
            warn "query log";
            warn YAML::Dump(Mock::Basic->profiler->query_log);
        }
    };
};

