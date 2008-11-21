use strict;
use warnings;
use Test::Declare;
use lib './t';
use Skinny;
use Data::Dumper;

plan tests => blocks;

describe 'basic search' => run {
    init {
        Skinny->do(q{
            CREATE TABLE user (
                id     INT,
                name   TEXT,
                date   TEXT
            )
        });
        Skinny->insert('user',{id => 1, name => 'nekokak',  date => '2008-09-09'});
        Skinny->insert('user',{id => 2, name => 'nomaneko', date => '2008-12-31'});
        Skinny->do(q{
            CREATE TABLE prof (
                id      INT,
                user_id INT,
                mail    TEXT,
                date    TEXT
            )
        });
        Skinny->insert('prof',{id => 1, user_id => 1, mail => 'nekokak@gmail.com',  date => '2008-09-09'});
        Skinny->insert('prof',{id => 2, user_id => 2, mail => 'nomaneko@example.com', date => '2008-12-31'});
    };
    test 'select wantarray' => run {
        my $sql = q{SELECT user.date, prof.date AS prof_date FROM user, prof WHERE user.id = prof.user_id};
        my @rows = map { +{date => $_->date, prof_date => $_->prof_date} } Skinny->search_by_sql($sql);
        is_deeply \@rows, [
            {
                'date' => '2008-09-09T00:00:00',
                'prof_date' => '2008-09-09T00:00:00',
            },
            {
                'date' => '2008-12-31T00:00:00',
                'prof_date' => '2008-12-31T00:00:00',
            }
        ];
    };
    test 'select iterator' => run {
        my $sql = q{SELECT user.date, prof.date AS prof_date FROM user, prof WHERE user.id = prof.user_id};
        my $it = Skinny->search_by_sql($sql);
        my @rows;
        while (my $row = $it->next) {
            push @rows, $row->get_columns;
        }
        is_deeply \@rows, [
            {
                'date' => '2008-09-09T00:00:00',
                'prof_date' => '2008-09-09T00:00:00',
            },
            {
                'date' => '2008-12-31T00:00:00',
                'prof_date' => '2008-12-31T00:00:00',
            }
        ];

        $it->reset;
        my @cache_rows;
        while (my $row = $it->next) {
            push @cache_rows, {date => $row->date, prof_date => $row->prof_date};
        }
        is_deeply \@rows, [
            {
                'date' => '2008-09-09T00:00:00',
                'prof_date' => '2008-09-09T00:00:00',
            },
            {
                'date' => '2008-12-31T00:00:00',
                'prof_date' => '2008-12-31T00:00:00',
            }
        ];
    };


    cleanup {
        Skinny->do(q{DROP TABLE user});
        Skinny->do(q{DROP TABLE prof});
    };
};


