package Mock::DB;
use DBIx::Skinny setup => +{
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_db (
            id   INT,
            name TEXT
        )
    });
}

1;

