package DBIx::Skinny::Row;
use strict;
use warnings;
use DBIx::Skinny::Accessor;
use Carp;

mk_accessors(qw/ row_data skinny select_columns /);

sub setup {
    my $self = shift;
    my $class = ref $self;

    $self->select_columns([keys %{$self->row_data}]);

    for my $alias ( @{$self->select_columns} ) {
        (my $col = lc $alias) =~ s/.+\.(.+)/$1/o;
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = $self->_razy_get_data($col);
    }
}

sub _razy_get_data {
    my ($self, $col) = @_;

    return sub {
        my $self = shift;
        my $data = $self->get_column($col);

        # inflate
        my $inflate_rules = $self->skinny->schema->inflate_rules;
        for my $rule (keys %{$inflate_rules}) {
            if ($col =~ /$rule/ and my $code = $inflate_rules->{$rule}->{inflate}) {
                $data = $code->($data);
            }
        }
        return $data;
    };
}

sub get_column {
    my ($self, $col) = @_;

    my $data = $self->row_data->{$col};

    $data = $self->skinny->schema->utf8_on($col, $data);

    return $data;
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $col ( @{$self->select_columns} ) {
        $data{$col} = $self->get_column($col);
    }
    return \%data;
}

sub update {
    my ($self, $table, $args) = @_;
    my $where = $self->_update_or_delete_cond($table);
    $self->skinny->update($table, $args, $where);
}

sub delete {
    my ($self, $table) = @_;
    my $where = $self->_update_or_delete_cond($table);
    $self->skinny->delete($table, $where);
}

sub _update_or_delete_cond {
    my ($self, $table) = @_;

    my $schema_info = $self->skinny->schema->schema_info;
    unless ( $schema_info->{$table} ) {
        croak "unknown table: $table";
    }

    # get target table pk
    my $pk = $schema_info->{$table}->{pk};
    unless ($pk) {
        croak "$table have no pk.";
    }

    unless (grep { $pk eq $_ } @{$self->select_columns}) {
        croak "can't get primary column in your query.";
    }

    return +{ $pk => $self->$pk };
}

1;

