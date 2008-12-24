package Mock::Inflate;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_inflate (
            id   INT,
            name TEXT
        )
    });
}

1;

