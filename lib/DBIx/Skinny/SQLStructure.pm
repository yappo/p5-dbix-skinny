package DBIx::Skinny::SQLStructure;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use SQL::Parser;

__PACKAGE__->mk_accessors(qw/stmt _structure _parser/);

sub parser {
    my $self = shift;
    $self->_parser or do {
        $self->_parser(SQL::Parser->new('AnyData',{PrintError => 0, RaiseError => 0}));
    };
}

sub structure {
    my $self = shift;
    $self->_structure or do {
        $self->parser->parse($self->stmt);
        $self->_structure(
            $self->parser->structure
        );
    };
}

1;

