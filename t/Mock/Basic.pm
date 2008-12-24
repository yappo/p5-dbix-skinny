package Mock::Basic;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_basic (
            id   INT,
            name TEXT
        )
    });
}

1;

