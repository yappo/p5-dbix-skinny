package DBIx::Skinny::Profiler;
use strict;
use warnings;
use DBIx::Skinny::Accessor;

mk_accessors(qw/ query_log /);

sub init {
    my $self = shift;
    $self->reset;
}

sub reset {
    my $self = shift;
    $self->query_log([]);
}

sub _normalize {
    my $sql = shift;
    $sql =~ s/^\s*//;
    $sql =~ s/\s*$//;
    $sql =~ s/[\r\n]/ /g;
    return $sql;
}

sub record_query {
    my ($self, $sql) = @_;

    $sql = _normalize($sql);

    push @{ $self->query_log }, $sql;
}

1;

