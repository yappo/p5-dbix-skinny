package DBIx::Skinny::Row;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Carp;
use Sub::Install qw/install_sub/;
use Data::Dumper;

__PACKAGE__->mk_accessors(qw/ row_data skinny select_columns sql_structure/);

sub structure {
    shift->sql_structure->structure;
}

sub setup {
    my $self = shift;

    my $class = ref $self;
    for my $alias (keys %{$self->structure->{column_aliases}}) {
        (my $col = lc $alias) =~ s/.+\.(.+)/$1/o;
        next if $class->can($col);
        install_sub({
            code => $self->_razy_inflate_data($col),
            as   => $col
        });
    }

    $self->select_columns([map { $_->display_name } values %{$self->structure->{col_obj}}]);
}

sub _razy_inflate_data {
    my ($self, $col) = @_;

    return sub {
        my $self = shift;
        my $table = $self->_get_column_belonging_table($col);
        my $org_col = $self->_get_original_column_name($col);

        if ( $org_col and my $code = $self->skinny->_schemas->{$table}->inflate($org_col) ) {
            return $code->($self->get_column($col));
        } else {
            return $self->get_column($col);
        }
    };
}

sub _get_column_belonging_table {
    my ($self, $col) = @_;

    my $table;
    if ( scalar(@{$self->structure->{table_names}}) == 1 ) {
        return lc $self->structure->{table_names}->[0];
    }

    for my $obj ( values %{$self->structure->{col_obj}} ) {
        if ($obj->display_name eq $col && $obj->table) {
            return lc $obj->table;
        }
    }
}

sub _get_original_column_name {
    my ($self, $col) = @_;

    for my $obj ( values %{$self->structure->{col_obj}} ) {
        if ($obj->display_name eq $col && $obj->table) {
            return lc $obj->name;
        }
    } 
    return $col;
}

sub get_column {
    my ($self, $col) = @_;

    my $data = $self->row_data->{$col};
    my $table = $self->_get_column_belonging_table($col);

    if ( $table ) {
        $self->skinny->call_schema_trigger('post_search', $table, { $col => \$data})
    }

    return $data;
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $col ( @{$self->select_columns} ) {
        $data{$col} = $self->$col;
    }
    return \%data;
}

sub update {
    my ($self, $args) = @_;
    my ($table, $where) = $self->_update_or_delete_cond;
    $self->skinny->update($table, $args, $where);
}

sub delete {
    my $self = shift;
    my ($table, $where) = $self->_update_or_delete_cond;
    $self->skinny->delete($table, $where);
}

sub _update_or_delete_cond {
    my $self = shift;

    if ( scalar(@{$self->structure->{table_names}}) > 1 ) {
        croak "can't update or delete. This query has many tables.";
    }

    my $table = lc $self->structure->{table_names}->[0];
    my $schema = $self->skinny->_schemas->{$table};
    unless ( $schema ) {
        croak "unknown table @{[$self->structure->{table_names}->[0]]}.";
    }

    my $pk = $self->skinny->_schemas->{$table}->pk;
    unless ( $pk ) {
        croak "$table has no primary key.";
    }

    my $pk_col = lc( $self->structure->{ORG_NAME}->{uc $pk}
               || $self->structure->{ORG_NAME}->{uc($table.'.'.$pk)});
    unless ( $pk_col ) {
        croak "can't get primary column.";
    }

    return ($table, +{$pk => $self->$pk_col});
}

1;

