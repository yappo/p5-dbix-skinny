package DBIx::Skinny;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw/Class::Data::Inheritable/;
use Module::Find;
use UNIVERSAL::require;
use DBI;
use DBIx::Skinny::Iterator;
use DBIx::Skinny::SQLStructure;
use DBIx::Skinny::DBD;
use DBIx::Skinny::SQL;
use Digest::SHA1 qw/sha1_hex/;

use Data::Dumper;

__PACKAGE__->mk_classdata($_) for qw/dsn username password _dbh dbd/;
__PACKAGE__->mk_classdata(_schemas => {} );

sub setup {
    my ($class, %args) = @_;

    for my $accesser ( keys %args ) {
        $class->$accesser( $args{$accesser} );
    }

    $class->_load_schemas;
    $class->_setup_dbd;
}

sub _load_schemas {
    my $class = shift;

    for my $schema (Module::Find::findallmod($class)) {
        $schema->use or die $@;
        ## $class  : Proj::Schema
        ## $schema : Proj::Schema::User
        ## $table  : User -> user
        my $table = lc substr $schema, length "${class}::";
        $class->_schemas->{$table} = $schema;
    }
}

sub _setup_dbd {
    my $class = shift;
    (my $dbd_type = $class->dsn) =~ s/^dbi:(\w*):.*/$1/;
    $class->dbd(DBIx::Skinny::DBD->new($dbd_type));
}

sub _connect {
    my $class = shift;
    return $class->_dbh if $class->_dbh;

    $class->_dbh(DBI->connect($class->dsn, $class->username, $class->password));
}

sub dbh { shift->_connect }

sub resultset {
    my ($class, $args) = @_;
    $args->{skinny} = $class;
    DBIx::Skinny::SQL->new($args);
}

sub do {
    my ($class, $sql) = @_;
    $class->dbh->do($sql);
}

sub call_schema_trigger {
    my ($class, $trigger, $table, $args) = @_;
    $class->_schemas->{$table}->call_trigger($trigger, $args); 
}

sub insert {
    my ($class, $table, $args) = @_;

    $class->call_schema_trigger('pre_insert', $table, $args);

    my (@cols,@bind);
    for my $col (keys %{ $args }) {
        push @cols, $col;
        push @bind, $args->{$col};
    }

    # TODO: INSERT or REPLACE. bind_param_attributes etc...
    my $sql = "INSERT INTO $table\n";
    $sql .= '(' . join(', ', @cols) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @cols) . ')' . "\n";

    my $sth = $class->_execute($sql, \@bind);

    my $id = $class->dbd->last_insert_id($class->dbh, $sth);
    my $obj = $class->search($table, { $class->_schemas->{$table}->pk => $id } )->first;

    $class->call_schema_trigger('post_insert', $table, $obj);

    $obj;
}

sub update {
    my ($class, $table, $args, $where) = @_;

    $class->call_schema_trigger('pre_update', $table, $args);

    my (@set,@bind);
    for my $col (keys %{ $args }) {
        push @set, "$col = ?";
        push @bind, $args->{$col};
    }

    my $stmt = DBIx::Skinny::SQL->new;
    $class->_add_where($stmt, $where);
    push @bind, @{ $stmt->bind };

    my $sql = "UPDATE $table SET " . join(', ', @set) . ' ' . $stmt->as_sql_where;

    $class->_execute($sql, \@bind);

    $class->call_schema_trigger('post_update', $table, $args);
}

sub delete {
    my ($class, $table, $where) = @_;

    $class->call_schema_trigger('pre_delete', $table, $where);

    my $stmt = DBIx::Skinny::SQL->new(
        {
            from => [$table],
        }
    );

    $class->_add_where($stmt, $where);

    my $sql = "DELETE " . $stmt->as_sql;
    $class->_execute($sql, $stmt->bind);

    $class->call_schema_trigger('post_delete', $table);
}

sub _add_where {
    my ($class, $stmt, $where) = @_;
    for my $col (keys %{$where}) {
        $stmt->add_where($col => $where->{$col});
    }
}

sub _setup_sqlstructure {
    my ($class, $stmt) = @_;

    return DBIx::Skinny::SQLStructure->new({stmt => $stmt});
}

sub search {
    my ($class, $table, $where, $opt) = @_;

    my $cols = $opt->{select} || $class->_schemas->{$table}->columns;
    my $rs = $class->resultset(
        {
            select => $cols,
            from   => [$table],
        }
    );

    $class->_add_where($rs, $where);

    $rs->limit(   $opt->{limit}   ) if $opt->{limit};
    $rs->offset(  $opt->{offset}  ) if $opt->{offset};

    if (my $terms = $opt->{order_by}) {
        my @orders;
        for my $term (@{$terms}) {
            my ($col, $case) = each %$term;
            push @orders, { column => $col, desc => $case };
        }
        $rs->order(\@orders);
    }

    if (my $terms = $opt->{having}) {
        for my $col (keys %$terms) {
            $rs->add_having($col => $terms->{$col});
        }
    }

    $rs->retrieve;
}

sub search_by_sql {
    my ($class, $sql, @bind) = @_;

    my $structure = $class->_setup_sqlstructure($sql);

    my $sth = $class->_execute($sql, \@bind);
    return $class->_get_iterator($sth, $structure);
}

sub _get_iterator {
    my ($class, $sth, $structure) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny        => $class,
        sth           => $sth,
        sql_structure => $structure,
        row_class     => $class->_mk_row_class_by_stmt($structure),
    );
}

sub _mk_row_class_by_stmt {
    my ($class, $structure) = @_;

    my $row_class = 'DBIx::Skinny::Row::C' . sha1_hex $structure->stmt . $$ . $structure;

    { no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skinny::Row'); }  ## no critic

    return $row_class;
}

sub _execute {
    my ($class, $stmt, $bind) = @_;

    my $sth = $class->dbh->prepare($stmt);
    $sth->execute(@{$bind});
   return $sth;
}

sub _close_sth {
    my ($class, $sth) = @_;
    $sth->finish;
    undef $sth;
}

1;

