package Mock::DBH::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_dbh => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

