package Mock::UTF8;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_utf8 (
            id   INT,
            name TEXT
        )
    });
}

1;

