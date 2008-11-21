package DBIx::Skinny::Iterator;
use strict;
use warnings;
use DBIx::Skinny::Row;

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    $self->reset;

    return wantarray ? $self->all : $self;
}

sub iterator {
    my $self = shift;

    my $potition = $self->{_potition} + 1;
    if ( my $row_cache = $self->{_rows_cache}->[$potition] ) {
        $self->{_potition} = $potition;
        return $row_cache;
    }

    my $row = $self->{sth}->fetchrow_hashref();
    unless ( $row ) {
        $self->{skinny}->_close_sth($self->{sth});
        return;
    }

    my $obj = DBIx::Skinny::Row->new(
        {
            row_data      => $row,
            skinny        => $self->{skinny},
            sql_structure => $self->{sql_structure},
        }
    );
    $obj->setup;

    $self->{_rows_cache}->[$potition] = $obj;
    $self->{_potition} = $potition;

    return $obj;
}

sub first {
    my $self = shift;
    $self->reset;
    $self->next;
}

sub next {
    my $self = shift;
    $self->iterator;
}

sub all {
    my $self = shift;
    my @result;
    while ( my $row = $self->next ) {
        push @result, $row;
    }
    return @result;
}

sub reset {
    my $self = shift;
    $self->{_potition} = 0;
    return $self;
}

1;

