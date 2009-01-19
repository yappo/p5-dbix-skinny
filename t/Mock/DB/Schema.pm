package Mock::DB::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_db => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

