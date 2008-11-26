package DBIx::Skinny::SQL;
use strict;
use warnings;
use Class::Accessor::Lite;

Class::Accessor::Lite->mk_accessors(
    qw/
        select distinct select_map select_map_reverse
        from joins where bind limit offset group order
        having where_values column_mutator index_hint
        comment
    /
);

sub new {
    my ($class, $args) = @_;
    my $stmt = bless {%{$args||{}}}, $class;

    $stmt->select([]);
    $stmt->distinct(0);
    $stmt->select_map({});
    $stmt->select_map_reverse({});
    $stmt->bind([]);
    $stmt->from([]);
    $stmt->where([]);
    $stmt->where_values({});
    $stmt->having([]);
    $stmt->joins([]);
    $stmt->index_hint({});
    $stmt;
}

sub add_select {
    my $stmt = shift;
    my($term, $col) = @_;
    $col ||= $term;
    push @{ $stmt->select }, $term;
    $stmt->select_map->{$term} = $col;
    $stmt->select_map_reverse->{$col} = $term;
}

sub add_join {
    my $stmt = shift;
    my($table, $joins) = @_;
    push @{ $stmt->joins }, {
        table => $table,
        joins => ref($joins) eq 'ARRAY' ? $joins : [ $joins ],
    };
}

sub add_index_hint {
    my $stmt = shift;
    my($table, $hint) = @_;
    $stmt->index_hint->{$table} = {
        type => $hint->{type} || 'USE',
        list => ref($hint->{list}) eq 'ARRAY' ? $hint->{list} : [ $hint->{list} ],
    };
}

sub as_sql {
    my $stmt = shift;
    my $sql = '';
    if (@{ $stmt->select }) {
        $sql .= 'SELECT ';
        $sql .= 'DISTINCT ' if $stmt->distinct;
        $sql .= join(', ',  map {
            my $alias = $stmt->select_map->{$_};
            $alias && /(?:^|\.)\Q$alias\E$/ ? $_ : "$_ $alias";
        } @{ $stmt->select }) . "\n";
    }
    $sql .= 'FROM ';

    ## Add any explicit JOIN statements before the non-joined tables.
    if ($stmt->joins && @{ $stmt->joins }) {
        my $initial_table_written = 0;
        for my $j (@{ $stmt->joins }) {
            my($table, $joins) = map { $j->{$_} } qw( table joins );
            $table = $stmt->_add_index_hint($table); ## index hint handling
            $sql .= $table unless $initial_table_written++;
            for my $join (@{ $j->{joins} }) {
                $sql .= ' ' .
                        uc($join->{type}) . ' JOIN ' . $join->{table} . ' ON ' .
                        $join->{condition};
            }
        }
        $sql .= ', ' if @{ $stmt->from };
    }

    if ($stmt->from && @{ $stmt->from }) {
        $sql .= join ', ', map { $stmt->_add_index_hint($_) } @{ $stmt->from };
    }

    $sql .= "\n";
    $sql .= $stmt->as_sql_where;

    $sql .= $stmt->as_aggregate('group');
    $sql .= $stmt->as_sql_having;
    $sql .= $stmt->as_aggregate('order');

    $sql .= $stmt->as_limit;
    my $comment = $stmt->comment;
    if ($comment && $comment =~ /([ 0-9a-zA-Z.:;()_#&,]+)/) {
        $sql .= "-- $1" if $1;
    }
    return $sql;
}

sub as_limit {
    my $stmt = shift;
    my $n = $stmt->limit or
        return '';
    die "Non-numerics in limit clause ($n)" if $n =~ /\D/;
    return sprintf "LIMIT %d%s\n", $n,
           ($stmt->offset ? " OFFSET " . int($stmt->offset) : "");
}

sub as_aggregate {
    my $stmt = shift;
    my($set) = @_;

    if (my $attribute = $stmt->$set()) {
        my $elements = (ref($attribute) eq 'ARRAY') ? $attribute : [ $attribute ];
        return uc($set) . ' BY '
            . join(', ', map { $_->{column} . ($_->{desc} ? (' ' . $_->{desc}) : '') } @$elements)
                . "\n";
    }

    return '';
}

sub as_sql_where {
    my $stmt = shift;
    $stmt->where && @{ $stmt->where } ?
        'WHERE ' . join(' AND ', @{ $stmt->where }) . "\n" :
        '';
}

sub as_sql_having {
    my $stmt = shift;
    $stmt->having && @{ $stmt->having } ?
        'HAVING ' . join(' AND ', @{ $stmt->having }) . "\n" :
        '';
}

sub add_where {
    my $stmt = shift;
    ## xxx Need to support old range and transform behaviors.
    my($col, $val) = @_;
    Carp::croak("Invalid/unsafe column name $col") unless $col =~ /^[\w\.]+$/;
    my($term, $bind, $tcol) = $stmt->_mk_term($col, $val);
    push @{ $stmt->{where} }, "($term)";
    push @{ $stmt->{bind} }, @$bind;
    $stmt->where_values->{$tcol} = $val;
}

sub add_complex_where {
    my $stmt = shift;
    my ($terms) = @_;
    my ($where, $bind) = $stmt->_parse_array_terms($terms);
    push @{ $stmt->{where} }, $where;
    push @{ $stmt->{bind} }, @$bind;
}

sub _parse_array_terms {
    my $stmt = shift;
    my ($term_list) = @_;

    my @out;
    my $logic = 'AND';
    my @bind;
    foreach my $t ( @$term_list ) {
        if (! ref $t ) {
            $logic = $1 if uc($t) =~ m/^-?(OR|AND|OR_NOT|AND_NOT)$/;
            $logic =~ s/_/ /;
            next;
        }
        my $out;
        if (ref $t eq 'HASH') {
            # bag of terms to apply $logic with
            my @out;
            foreach my $t2 ( keys %$t ) {
                my ($term, $bind, $col) = $stmt->_mk_term($t2, $t->{$t2});
                $stmt->where_values->{$col} = $t->{$t2};
                push @out, $term;
                push @bind, @$bind;
            }
            $out .= '(' . join(" AND ", @out) . ")";
        }
        elsif (ref $t eq 'ARRAY') {
            # another array of terms to process!
            my ($where, $bind) = $stmt->_parse_array_terms( $t );
            push @bind, @$bind;
            $out = '(' . $where . ')';
        }
        push @out, (@out ? ' ' . $logic . ' ' : '') . $out;
    }
    return (join("", @out), \@bind);
}

sub has_where {
    my $stmt = shift;
    my($col, $val) = @_;

    # TODO: should check if the value is same with $val?
    exists $stmt->where_values->{$col};
}

sub add_having {
    my $stmt = shift;
    my($col, $val) = @_;

    if (my $orig = $stmt->select_map_reverse->{$col}) {
        $col = $orig;
    }

    my($term, $bind) = $stmt->_mk_term($col, $val);
    push @{ $stmt->{having} }, "($term)";
    push @{ $stmt->{bind} }, @$bind;
}

sub _mk_term {
    my $stmt = shift;
    my($col, $val) = @_;
    my $term = '';
    my (@bind, $m);
    if (ref($val) eq 'ARRAY') {
        if (ref $val->[0] or (($val->[0] || '') eq '-and')) {
            my $logic = 'OR';
            my @values = @$val;
            if ($val->[0] eq '-and') {
                $logic = 'AND';
                shift @values;
            }

            my @terms;
            for my $v (@values) {
                my($term, $bind) = $stmt->_mk_term($col, $v);
                push @terms, "($term)";
                push @bind, @$bind;
            }
            $term = join " $logic ", @terms;
        } else {
            $col = $m->($col) if $m = $stmt->column_mutator;
            $term = "$col IN (".join(',', ('?') x scalar @$val).')';
            @bind = @$val;
        }
    } elsif (ref($val) eq 'HASH') {
        my $c = $val->{column} || $col;
        $c = $m->($c) if $m = $stmt->column_mutator;
        $term = "$c $val->{op} ?";
        push @bind, $val->{value};
    } elsif (ref($val) eq 'SCALAR') {
        $col = $m->($col) if $m = $stmt->column_mutator;
        $term = "$col $$val";
    } else {
        $col = $m->($col) if $m = $stmt->column_mutator;
        $term = "$col = ?";
        push @bind, $val;
    }
    ($term, \@bind, $col);
}

sub _add_index_hint {
    my $stmt = shift;
    my ($tbl_name) = @_;
    my $hint = $stmt->index_hint->{$tbl_name};
    return $tbl_name unless $hint && ref($hint) eq 'HASH';
    if ($hint->{list} && @{ $hint->{list} }) {
        return $tbl_name . ' ' . uc($hint->{type} || 'USE') . ' INDEX (' . 
                join (',', @{ $hint->{list} }) .
                ')';
    }
    return $tbl_name;
}

'base code from Data::ObjectDriver::SQL';
