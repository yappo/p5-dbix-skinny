use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'find_or_create test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'find_or_create' => run {
        my $mock_basic = Mock::Basic->find_or_create('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        is $mock_basic->name, 'perl';

        $mock_basic = Mock::Basic->find_or_create('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        is $mock_basic->name, 'perl';

        my @rows = Mock::Basic->search('mock_basic')->all;
        is scalar(@rows), 1;
    };
};

