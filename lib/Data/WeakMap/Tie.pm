package Data::WeakMap::Tie;
use 5.014;
use warnings FATAL => 'all';

use Sentinel;

use Scalar::Util 'weaken', 'isweak';
use Carp 'croak';

our $VERSION = "v0.0.3";

sub TIEHASH {
    my ($class, $mbp) = @_;

    my $self = [$mbp];
    weaken($self->[0]);

    bless $self, $class;
}

sub STORE {
    my ($self, $key, $value) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };
    my $key_str = "$key";

    # the order of the following statements matters apparently (on perl 5.30.2)
    weaken($struct->{keys}{$key_str} = $key);
    $struct->{triggers}{$key_str} = \sentinel(
        value => $key,
        set   => sub {

            # checking $struct is needed here because otherwise we get
            # crashes when the map and its data get destroyed after a few
            # 'eaches'

            # TODO: Investigate (because might mean a memory leak, like
            # TODO: the sentinel staying alive for the lifetime of $key,
            # TODO: even after $map has been destroyed.
            # TODO: Furthermore, since 'set' is holding a ref to $self
            # TODO: i.e. tied($mbp), it could well be that it is not
            # TODO: letting it die.

            if (! defined $_[0] and $struct) {
                $self->DELETE($key_str);
            }
        },
    );
    weaken(${ $struct->{triggers}{$key_str} });
    $struct->{values}{$key_str} = $value;

    return $value;
}

sub FETCH {
    my (undef, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };

    return $struct->{values}{$key};
}

sub DELETE {
    my (undef, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '' and caller ne 'Data::WeakMap::Tie';

    my $struct = ${ $_[0][0] };
    my $key_str = "$key";

    delete $struct->{$_}{$key_str} foreach qw/ keys triggers /;
    return delete $struct->{values}{$key_str};
}

sub CLEAR {
    # my ($self) = @_;

    my $struct = ${ $_[0][0] };

    %{ $struct->{$_} } = () foreach qw/ keys triggers values /;
}

sub EXISTS {
    my (undef, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };

    return exists $struct->{keys}{$key};
}

sub FIRSTKEY {
    # my ($self) = @_;

    my $struct = ${ $_[0][0] };

    my $z = keys %{ $struct->{keys} };

    return (each %{ $struct->{keys} })[1];

    # # Following version gives the same exact results in tests
    # # (although in an event loop, it will be easy to weaken)
    # my ($k, $v) = each %{ $struct->{keys} };
    #
    # weaken($v);
    # return $v;
}

sub NEXTKEY {
    # my ($self, $lastkey) = @_;

    my $struct = ${ $_[0][0] };

    return (each %{ $struct->{keys} })[1];

    # # Following version gives the same exact results in tests
    # # (although in an event loop, it will be easy to weaken)
    # my ($k, $v) = each %{ $struct->{keys} };
    #
    # weaken($v);
    # return $v;
}

sub SCALAR {
    # my ($self) = @_;

    my $struct = ${ $_[0][0] };

    return scalar %{ $struct->{values} };
}

1;
