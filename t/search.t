use strict;
use warnings;
use Test::Declare;
use lib './t';
use utf8;
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
        Skinny->do(q{
            CREATE TABLE job (
                id         INT,
                name       TEXT,
                created_on TEXT
            )
        });
    };
    test 'insert hook' => run {
        Skinny->insert(job => { id => 1, name => 'あああああ' });
        my @rows = map { $_->get_columns } Skinny->search('job');
        is_deeply \@rows, [
            {
                id => 1,
                name => 'あああああ',
                created_on => DateTime->today,
            }
        ];
    };
    test 'select' => run {
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
    test 'abstract search' => run {
        my @rows = map { +{id => $_->id, date => $_->date} } Skinny->search('user', {id => 1},{as => [qw/id date/]});
        is_deeply \@rows, [
            {
                'id'   => 1,
                'date' => '2008-09-09T00:00:00',
            },
        ];
    };
    test 'abstract search no as' => run {
        my @rows = map { +{id => $_->id, name => $_->name, date => $_->date} } Skinny->search('user', {id => 1});
        is_deeply \@rows, [
            {
                id   => 1,
                name => 'nekokak',
                date => '2008-09-09T00:00:00',
            },
        ];
    };
    test 'get_column' => run {
        my @rows = map { +{id => $_->get_column('id'), name => $_->get_column('name'), date => $_->get_column('date')} } Skinny->search('user', {id => 1});
        is_deeply \@rows, [
            {
                id   => 1,
                name => 'nekokak',
                date => '2008-09-09',
            },
        ];
    };
    test 'limit offset' => run {
        my @rows = map { $_->get_columns } Skinny->search('user', {}, { limit => 1,});
        is_deeply \@rows, [
            {
                id   => 1,
                name => 'nekokak',
                date => '2008-09-09T00:00:00',
            },
        ];

        @rows = map { $_->get_columns } Skinny->search('user', {}, { limit => 1, offset => 1});
        is_deeply \@rows, [
            {
                id   => 2,
                name => 'nomaneko',
                date => '2008-12-31T00:00:00',
            },
        ];
    };

    test 'order' => run {
        my @rows = map { $_->get_columns } Skinny->search('user', {}, { order_by => ['id ASC']});
        is_deeply \@rows, [
            {
                id   => 1,
                name => 'nekokak',
                date => '2008-09-09T00:00:00',
            },
            {
                id   => 2,
                name => 'nomaneko',
                date => '2008-12-31T00:00:00',
            },

        ];

        @rows = map { $_->get_columns } Skinny->search('user', {}, { order_by => ['id DESC']});
        is_deeply \@rows, [ 
            {
                id   => 2,
                name => 'nomaneko',
                date => '2008-12-31T00:00:00',
            },
            {
                id   => 1,
                name => 'nekokak',
                date => '2008-09-09T00:00:00',
            },
        ];
    };

    test 'update select' => run {
        Skinny->update(user => {name => 'nomanekoQ'},{id => 1});
        my @rows = map { +{name => $_->name} } Skinny->search_by_sql('SELECT name FROM user where id = ?',1);
        is_deeply \@rows, [ { name => 'nomanekoQ'} ];
        Skinny->update(user => {name => 'nekokak'},{id => 1});
    };
    test 'delete select' => run {
        Skinny->insert(user => {id => 3, name => 'fooooo', date => '2008-12-31'});
        my @rows = map { +{name => $_->name} } Skinny->search_by_sql('SELECT name FROM user where id = ?',3);
        is_deeply \@rows, [ { name => 'fooooo'} ];
        Skinny->delete(user => {id => 3});
        @rows = map { +{name => $_->name} } Skinny->search_by_sql('SELECT name FROM user where id = ?',3);
        is_deeply \@rows, [];
    };
    cleanup {
        Skinny->do(q{DROP TABLE user});
        Skinny->do(q{DROP TABLE prof});
    };
};


