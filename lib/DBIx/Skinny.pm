package DBIx::Skinny;
use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::require;
use DBI;
use DBIx::Skinny::Iterator;
use DBIx::Skinny::DBD;
use DBIx::Skinny::SQL;
use DBIx::Skinny::Row;

sub import {
    my ($class, %opt) = @_;

    my $caller = caller;
    my $args   = $opt{setup};

    my $schema = "$caller\::Schema";
    $schema->use or die $@;

    (my $dbd_type = $args->{dsn}) =~ s/^dbi:(\w*):.*/$1/;

    my $_attribute = +{
        dsn      => $args->{dsn},
        username => $args->{username},
        password => $args->{password},
        dbh      => '',
        dbd      => DBIx::Skinny::DBD->new($dbd_type),
        schema   => $schema,
    };
    no strict 'refs';
    *{"$caller\::attribute"} = sub { $_attribute };

    my @functions = qw/
        schema
        dbh _connect
        call_schema_trigger
        do resultset search single search_by_sql count
            _get_iterator _mk_row_class
        insert create update delete find_or_create find_or_insert
            _add_where
        _execute _close_sth
    /;
    for my $func (@functions) {
        *{"$caller\::$func"} = \&$func;
    }

    strict->import;
    warnings->import;
}

sub schema {
    my $class = shift;
    $class->attribute->{schema};
}

#--------------------------------------------------------------------------------
# db handling
sub _connect {
    my $class = shift;
    $class->attribute->{dbh} ||= DBI->connect(
        $class->attribute->{dsn},
        $class->attribute->{username},
        $class->attribute->{password},
    );
    $class->attribute->{dbh};
}

sub dbh { shift->_connect }

#--------------------------------------------------------------------------------
# schema trigger call
sub call_schema_trigger {
    my ($class, $trigger, $table, $args) = @_;
    $class->schema->call_trigger($class, $table, $trigger, $args);
}

#--------------------------------------------------------------------------------
sub do {
    my ($class, $sql) = @_;
    $class->dbh->do($sql);
}

sub count {
    my ($class, $table, $args, $where) = @_;

    my $rs = $class->resultset(
        {
            from   => [$table],
        }
    );

    my ($alias, $column) = each %$args;
    $rs->add_select("COUNT($column)" =>  $alias);
    $class->_add_where($rs, $where);

    $rs->retrieve->first;
}

sub resultset {
    my ($class, $args) = @_;
    $args->{skinny} = $class;
    DBIx::Skinny::SQL->new($args);
}

sub search {
    my ($class, $table, $where, $opt) = @_;

    my $cols = $opt->{select} || $class->schema->schema_info->{$table}->{columns};
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

sub single {
    my ($class, $table, $where, $opt) = @_;
    $opt->{limit} = 1;
    $class->search($table, $where, $opt)->first;
}

sub search_by_sql {
    my ($class, $sql, @bind) = @_;

    my $sth = $class->_execute($sql, \@bind);
    return $class->_get_iterator($sql, $sth);
}

sub _get_iterator {
    my ($class, $sql, $sth) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny    => $class,
        sth       => $sth,
        row_class => $class->_mk_row_class($sql),
    );
}

sub _mk_row_class {
    my ($class, $sql) = @_;

    my $row_class = 'DBIx::Skinny::Row::C';
    for my $i (0..(int(length($sql) / 8))) {
        $row_class .= crypt(substr($sql,($i*8),8), 'mk');
    }
    { no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skinny::Row'); }

    return $row_class;
}

*create = \*insert;
sub insert {
    my ($class, $table, $args) = @_;

    $class->call_schema_trigger('pre_insert', $table, $args);

    # deflate
    my $inflate_rules = $class->schema->inflate_rules;
    for my $rule (keys %{$inflate_rules}) {
        for my $col (keys %{$args}) {
            if ($col =~ /$rule/ and my $code = $inflate_rules->{$rule}->{deflate}) {
                $args->{$col} = $code->($args->{$col});
            }
        }
    }

    my (@cols,@bind);
    for my $col (keys %{ $args }) {
        push @cols, $col;
        push @bind, $class->schema->utf8_off($col, $args->{$col});
    }

    # TODO: INSERT or REPLACE. bind_param_attributes etc...
    my $sql = "INSERT INTO $table\n";
    $sql .= '(' . join(', ', @cols) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @cols) . ')' . "\n";

    my $sth = $class->_execute($sql, \@bind);

    my $id = $class->attribute->{dbd}->last_insert_id($class->dbh, $sth);
    my $obj = $class->search($table, { $class->schema->schema_info->{$table}->{pk} => $id } )->first;

    $class->call_schema_trigger('post_insert', $table, $obj);

    $obj;
}

sub update {
    my ($class, $table, $args, $where) = @_;

    $class->call_schema_trigger('pre_update', $table, $args);

    # deflate
    my $inflate_rules = $class->schema->inflate_rules;
    for my $rule (keys %{$inflate_rules}) {
        for my $col (keys %{$args}) {
            if ($col =~ /$rule/ and my $code = $inflate_rules->{$rule}->{deflate}) {
                $args->{$col} = $code->($args->{$col});
            }
        }
    }

    my (@set,@bind);
    for my $col (keys %{ $args }) {
        push @set, "$col = ?";
        push @bind, $class->schema->utf8_off($col, $args->{$col});
    }

    my $stmt = $class->resultset;
    $class->_add_where($stmt, $where);
    push @bind, @{ $stmt->bind };

    my $sql = "UPDATE $table SET " . join(', ', @set) . ' ' . $stmt->as_sql_where;

    $class->_execute($sql, \@bind);

    for my $col (@{$class->schema->schema_info->{$table}->{columns}}) {
        $stmt->add_select($col);
    }
    $stmt->from([$table]);
    my $row = $stmt->retrieve->first;

    $class->call_schema_trigger('post_update', $table, $row);

    return $row;
}

sub delete {
    my ($class, $table, $where) = @_;

    $class->call_schema_trigger('pre_delete', $table, $where);

    my $stmt = $class->resultset(
        {
            from   => [$table],
        }
    );

    $class->_add_where($stmt, $where);

    my $sql = "DELETE " . $stmt->as_sql;
    $class->_execute($sql, $stmt->bind);

    $class->call_schema_trigger('post_delete', $table);
}

*find_or_insert = \*find_or_create;

sub find_or_create {
    my ($class, $table, $args) = @_;
    my $row = $class->single($table, $args);
    return $row if $row;
    $row = $class->insert($table, $args);
    return $row;
}

sub _add_where {
    my ($class, $stmt, $where) = @_;
    for my $col (keys %{$where}) {
        $stmt->add_where($col => $where->{$col});
    }
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

