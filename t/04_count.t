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
        Mock->insert('tag',{
            id   => 1,
            name => 'perl',
        });
        my $row = Mock->count('tag' => {id => 'count'});
        is $row->count, 1;

        Mock->insert('tag',{
            id   => 2,
            name => 'ruby',
        });
        $row = Mock->count('tag' => {id => 'count'});
        is $row->count, 2;

        $row = Mock->count('tag' => {id => 'count'},{name => 'perl'});
        is $row->count, 1;
    };
};

