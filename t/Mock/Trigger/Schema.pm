package Mock::Trigger::Schema;
use DBIx::Skinny::Schema;

install_table mock_trigger_pre => schema {
    pk 'id';
    columns qw/
        id
        name
    /;

    trigger pre_insert => callback {
        my $args = shift;
        $args->{name} = 'pre_insert';
    };

    trigger post_insert => callback {
        my $obj = shift;
        $obj->skinny->insert('mock_trigger_post',{
            id   => 1,
            name => 'post_insert',
        });
    };

    trigger pre_update => callback {
        my $args = shift;
        $args->{name} = 'pre_update';
    };

    trigger post_update => callback {
        my $obj = shift;
        $obj->skinny->update('mock_trigger_post',{
            name => 'post_update',
        },{id => 1});
    };
};

install_table mock_trigger_post => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

