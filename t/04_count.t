use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'count test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'find_or_create' => run {
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        my $row = Mock::Basic->count('mock_basic' => {count => 'id'});
        is $row->count, 1;

        Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'ruby',
        });
        $row = Mock::Basic->count('mock_basic' => {count => 'id'});
        is $row->count, 2;

        $row = Mock::Basic->count('mock_basic' => {count => 'id'},{name => 'perl'});
        is $row->count, 1;
    };
};

