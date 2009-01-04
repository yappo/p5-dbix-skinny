use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use DBIx::Skinny::Profiler;

plan tests => blocks;

my $profiler = DBIx::Skinny::Profiler->new;

describe 'profiler test' => run {
    test 'record query' => run {
        $profiler->record_query(q{SELECT * FROM user});
        is_deeply $profiler->query_log, [
            q{SELECT * FROM user},
        ];

    };

    test 'record query /_normalize' => run {
        $profiler->record_query(q{
            SELECT
                id, name
            FROM
                user
            WHETE
                name like "%neko%"
        });
        is_deeply $profiler->query_log, [
            q{SELECT * FROM user},
            q{SELECT                 id, name             FROM                 user             WHETE                 name like "%neko%"},
        ];
    };

    test 'reset' => run {
        $profiler->reset;
        is_deeply $profiler->query_log, [];
    };
};

