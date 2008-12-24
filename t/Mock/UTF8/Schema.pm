package Mock::UTF8::Schema;
use DBIx::Skinny::Schema;

install_table mock_utf8 => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_utf8_columns qw/name/;

1;

