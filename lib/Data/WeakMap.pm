package Data::WeakMap;
use 5.016;
use strict;
use warnings FATAL => 'all';

use parent 'Data::ManBearPig';

our $VERSION = "v0.0.2";

sub new { shift->SUPER::new }

1;
__END__

=encoding utf-8

=head1 NAME

Data::WeakMap - WeakMap that behaves like a hash, and doesn't leak memory

=head1 SYNOPSIS

    use Data::WeakMap;

    my $map = Data::WeakMap->new;
    # or
    my \%map = Data::WeakMap->new;

    # Treat it just like a hash, but the keys must be perl references (of any kind)
    # For more see here: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap

    my \%map = Data::WeakMap->new;
    my $user = bless {name => 'Peter', age => 32}, 'MyWebSite::User';
    $map{$user} = int rand 100;
    print $map{$user}; # a number between 0 and 99

    my @users = ({name => 'Peter', age => 32}, {name => 'Mary', age => 29}, ...); # 100 users
    @map{@users} = @profiles; # map the users to 100 profiles
    $map{$users[ $i ]} == $profiles[ $i ];

    # you can do any hash operation on %map, except for 'each %map'.
    my @keys = keys %map; # as usual...
    my $num_keys = keys %map;
    foreach my $value (values %map) { ... }
    delete $map{ $users[0] };
    exists $map{ $users[0] };
    # etc

    # Here's the 'Weak' part of WeakMaps:
    my $regex = qr/123/;
    %map = ($regex, 5);
    scalar(keys %map); # 1
    {
        my $regex2 = qr/234/;
        $map{$regex2} = 10;
        scalar(keys %map); # 2
    }
    scalar(keys %map); # is now back to 1 (because WeakMap's keys, which are references, are only weak references)


=head1 DESCRIPTION

Data::WeakMap is a Perl implementation of WeakMaps that doesn't leak memory

(For more see here: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap)

=head1 CAVEATS

Don't do this, ever: C<each(%map)>.

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut
