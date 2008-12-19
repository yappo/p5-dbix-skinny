package Mock;

use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $class = shift;
    $class->do(q{
        CREATE TABLE tag (
            id         INT,
            guid       TEXT,
            name       TEXT,
            created_at TEXT
        )
    });
}

1;

