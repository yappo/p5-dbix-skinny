package DBIx::Skinny;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw/Class::Data::Inheritable/;
use SQL::Abstract::Limit;
use Module::Find;
use UNIVERSAL::require;
use DBI;
use DBIx::Skinny::Iterator;
use DBIx::Skinny::SQLStructure;
use DBIx::Skinny::DBD;

use Data::Dumper;

__PACKAGE__->mk_classdata($_) for qw/dsn username password _dbh dbd _sql_abstract/;
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
    (my $dbd_type = $class->dsn) =~ s/^dbi:(\w*):/$1/;
    $class->dbd(DBIx::Skinny::DBD->new($dbd_type));
}

sub _connect {
    my $class = shift;
    return $class->_dbh if $class->_dbh;

    $class->_dbh(DBI->connect($class->dsn, $class->username, $class->password));
}

sub dbh { shift->_connect }

sub do {
    my ($class, $sql) = @_;
    $class->dbh->do($sql);
}

sub sql_abstract {
    my $class = shift;
    $class->_sql_abstract or do {
        $class->_sql_abstract(SQL::Abstract::Limit->new(limit_dialect => $class->dbh));
    };
}

sub call_schema_trigger {
    my ($class, $trigger, $table, $args) = @_;
    $class->_schemas->{$table}->call_trigger($trigger, $args); 
}

sub insert {
    my ($class, $table, $args) = @_;

    $class->call_schema_trigger('pre_insert', $table, $args);
    
    my ($stmt, @bind) = $class->sql_abstract->insert($table, $args);
    my $sth = $class->_execute($stmt, \@bind);

    my $id = $class->dbd->last_insert_id($class->dbh, $sth);
    my $obj = $class->search($table, { $class->_schemas->{$table}->pk => $id } )->first;

    $class->call_schema_trigger('post_insert', $table, $obj);
}
sub update {
    my ($class, $table, $args, $where) = @_;

    $class->call_schema_trigger('pre_update', $table, $args);

    my ($stmt, @bind) = $class->sql_abstract->update($table, $args, $where);
    $class->_execute($stmt, \@bind);

    $class->call_schema_trigger('post_update', $table, $args);
}
sub delete {
    my ($class, $table, $where) = @_;

    $class->call_schema_trigger('pre_delete', $table, $where);

    my ($stmt, @bind) = $class->sql_abstract->delete($table, $where);
    $class->_execute($stmt, \@bind);

    $class->call_schema_trigger('post_delete', $table);
}

sub _setup_sqlstructure {
    my ($class, $stmt) = @_;

    return DBIx::Skinny::SQLStructure->new({stmt => $stmt});
}

sub search {
    my ($class, $table, $where, $opt) = @_;

    my $cols = $opt->{as} || $class->_schemas->{$table}->columns;
    my $order = $opt->{order_by};
    my ($limit, $offset) = ($opt->{limit}||0, $opt->{offset}||0);
    my ($stmt, @bind) = $class->sql_abstract->select($table, $cols, $where, $order, $limit, $offset);

    my $structure = $class->_setup_sqlstructure($stmt);

    my $sth = $class->_execute($stmt, \@bind);
    $class->_get_iterator($sth, $structure);
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
    );
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

