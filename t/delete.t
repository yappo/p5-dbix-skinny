use strict;
use warnings;
use Test::Declare;
use lib './t';
use Skinny;
use Data::Dumper;

plan tests => blocks;

describe 'basic delete' => run {
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
    test 'select' => run {
        my $sql = q{SELECT id FROM user WHERE id = 1};
        my @rows = Skinny->search_by_sql($sql);
        $rows[0]->delete;

        $sql = q{SELECT id, name FROM user};
        @rows = map {+{ id => $_->id, name => $_->name }} Skinny->search_by_sql($sql);
        is_deeply \@rows, [
            {
                id => 2,
                name => 'nomaneko',
            }
        ];
        Skinny->insert('user',{id => 1, name => 'nekokak',  date => '2008-09-09'});
    };
    test 'abstract search' => run {
        my @rows = Skinny->search('user', {id => 1},{select => [qw/id/]});
        $rows[0]->delete;

        @rows = map { +{id => $_->id, name => $_->name} } Skinny->search('user', {},{select => [qw/id name/]});
        is_deeply \@rows, [
            {
                id   => 2,
                name => 'nomaneko',
            },
        ];
        Skinny->insert('user',{id => 1, name => 'nekokak',  date => '2008-09-09'});
    };

    test 'join case' => run {
        my $sql = q{SELECT user.id FROM user, prof WHERE user.id = prof.user_id AND user.id = 1};
        my @rows = Skinny->search_by_sql($sql);
        dies_ok { $rows[0]->delete };
    };

    test 'no pk settings' => run {
        Skinny::User->pk(undef);
        my $sql = q{SELECT id FROM user WHERE id = 1};
        my @rows = Skinny->search_by_sql($sql);
        dies_ok { $rows[0]->delete };
        Skinny::User->pk('id');
    };

    test 'no pk in your query' => run {
        my $sql = q{SELECT name FROM user WHERE id = 1};
        my @rows = Skinny->search_by_sql($sql);
        dies_ok { $rows[0]->delete };
    };

    cleanup {
        Skinny->do(q{DROP TABLE user});
        Skinny->do(q{DROP TABLE prof});
    };
};


