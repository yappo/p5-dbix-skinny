use strict;
use warnings;
use Test::Declare;
use lib './t';
use utf8;
use Mock;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock->setup_test_db;
    };

    test 'find_or_create' => run {
        my $tag = Mock->find_or_create('tag',{
            id   => 1,
            name => 'perl',
        });
        is $tag->name, 'perl';

        $tag = Mock->find_or_create('tag',{
            id   => 1,
            name => 'perl',
        });
        is $tag->name, 'perl';

        my @rows = Mock->search('tag')->all;
        is scalar(@rows), 1;
    };
};

