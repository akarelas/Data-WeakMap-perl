package Data::ManBearPig;
use strict;
use warnings FATAL => 'all';

our $VERSION = "v0.0.3";

use overload '%{}'  => sub { ${$_[0]}->{dummy} }, fallback => 1;
use overload 'bool' => sub { 1 }, fallback => 1;

sub new {
    my ($class) = @_;

    my $self = \{
        keys      => {},
        values    => {},
        triggers  => {},
        dummy     => {},
    };

    require Data::WeakMap::Tie;
    tie %{ $$self->{dummy} }, 'Data::WeakMap::Tie', $self;

    bless $self, $class;
}

1;
