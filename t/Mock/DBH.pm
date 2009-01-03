package Mock::DBH;
use DBI;
use DBIx::Skinny setup => +{
    dbh => DBI->connect('dbi:SQLite:', '', ''),
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_dbh (
            id   INT,
            name TEXT
        )
    });
}

1;

