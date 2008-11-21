package DBIx::Skinny::Table;
use strict;
use warnings;
use base 'Class::Data::Inheritable';
use Class::Trigger qw/
    pre_insert post_insert
    pre_update post_update
    pre_delete post_delete
    pre_search post_search
/;

BEGIN {
    if ($] <= 5.008000) {
        require Encode;
    } else {
        require utf8;
    }
}

__PACKAGE__->mk_classdata($_) for qw/_inflate pk/;
__PACKAGE__->mk_classdata(columns => []);
__PACKAGE__->mk_classdata(_utf8_columns => {});

sub add_columns {
    my ($class, @columns) = @_;
    $class->columns(\@columns);
}

sub inflate_column {
    my ($class, $col, $args) = @_;
    $class->_inflate({}) unless $class->_inflate;
    $class->_inflate->{$col} = $args->{inflate};
}

sub inflate {
    my ($class, $col) = @_;
    return $class->_inflate->{$col};
}

sub utf8_columns {
    my ($class, @columns) = @_;
    $class->_utf8_columns({ map { $_ => 1 } @columns });
}

__PACKAGE__->add_trigger(
    post_search => sub {
        shift->_utf8_on(@_)
    }
);

__PACKAGE__->add_trigger(
    pre_insert => sub {
        shift->_utf8_off(@_)
    }
);

__PACKAGE__->add_trigger(
    pre_update => sub {
        shift->_utf8_off(@_)
    }
);

sub _utf8_on {
    my ($class, $args) = @_;

    my ($col, $data) = each %$args;
    return unless $class->_utf8_columns->{$col};

    if ($] <= 5.008000) {
        Encode::_utf8_on($$data) unless Encode::is_utf8($$data);
    } else {
        utf8::decode($$data) unless utf8::is_utf8($$data);
    }
}

sub _utf8_off {
    my ($class, $args) = @_;
    for my $col (keys %{$args}) {
        next unless $class->_utf8_columns->{$col};
        if ($] <= 5.008000) {
            Encode::_utf8_off($args->{$col}) if Encode::is_utf8($args->{$col});
        } else {
            utf8::encode($args->{$col}) if utf8::is_utf8($args->{$col});
        }
    }
}

1;

