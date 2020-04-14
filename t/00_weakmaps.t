use strict;
use warnings FATAL => 'all';
# use warnings;
use File::Spec::Functions;
use lib "local/lib/perl5";

use Test::More 0.98;
use Test::Deep;
use lib "t/lib";

use Data::WeakMap;
use Data::WeakMap::TestModule 'safe_is_size_and_weakness', 'is_size_and_weakness';

use Scalar::Util 'isweak', 'refaddr';
use Devel::Confess 'color';

plan tests => 9;

sub underlying_structure {
    my ($map) = @_;

    return ${ tied(%$map)->[0] };
}

subtest 'store & retrieve key/value pair' => sub {
    plan tests => 9;

    my $map = Data::WeakMap->new;
    isa_ok($map, 'Data::WeakMap', 'new WeakMap');

    my $key1 = [ 'foo', 123 ];
    my $key2 = { foo => 123 };
    my $key3 = [ 10 ];

    note 'inserting a value';
    $map->{$key1} = 5;

    is_size_and_weakness($map, 1);
    is(keys(%$map), 1, 'weakmap has exactly one key');

    note 'inserting a value';
    $map->{$key2} = 10;
    is_size_and_weakness($map, 2);
    is(keys(%$map), 2, 'weakmap has exactly two keys');

    is($map->{$key1}, 5, 'fetch WeakMap value for first key');
    is($map->{$key2}, 10, 'fetch WeakMap value for second key');
    is($map->{$key3}, undef, 'fetch WeakMap value for third, non-existent, key');

    is_size_and_weakness($map, 2);
};

subtest 'key/value pairs get deleted when key falls out of scope' => sub {
    plan tests => 4;

    my $map = Data::WeakMap->new;

    note 'inserting a key';
    my $key1 = [ 'foo', 123 ];
    $map->{$key1} = 5;
    is_size_and_weakness($map, 1);

    note 'opening a block, and inserting a value with a scoped key';
    {
        my $key2 = { foo => 123 };
        $map->{$key2} = 10;
        safe_is_size_and_weakness($map, 2);
        is_size_and_weakness($map, 2);
        note 'closing the block';
    }

    is_size_and_weakness($map, 1);
};

subtest 'full iteration (e.g. "keys %$map", "values %$map", "%$map") attempt' => sub {
    plan tests => 9;

    my $map = Data::WeakMap->new;

    note 'opening a block';
    {
        note 'setting 3 scoped lexical keys to %$map';
        my @input_keys = ([10], [20], [30]);
        @$map{@input_keys} = map {$_->[0] * 10} @input_keys;

        safe_is_size_and_weakness($map, 3);

        cmp_deeply([map refaddr($_), @input_keys], bag(map refaddr($_), keys %$map),
            'keys(%$map) have the same refaddr as the keys inserted');

        cmp_deeply([100, 200, 300], bag(values %$map), 'values(%$map) are correct');

        cmp_deeply([%$map], bag(@input_keys, 100, 200, 300), '%$map returns the correct 6 elements');

        safe_is_size_and_weakness($map, 3);
        is_size_and_weakness($map, 3);
        note 'exiting the block';
    }

    safe_is_size_and_weakness($map, 0);
    is_size_and_weakness($map, 0);
    is(keys(%$map), 0, 'map has lost its keys');
};

subtest 'delete keys' => sub {
    plan tests => 5;

    my $map = Data::WeakMap->new;

    my @input_keys = ([10], [20], [30]);

    note 'inserting 3 keys';
    $map->{$_} = $_->[0] * 10 foreach @input_keys;
    is_size_and_weakness($map, 3);

    note 'deleting one key';
    my $ret = delete $map->{$input_keys[1]};
    is($ret, 200, 'delete returns the correct value');

    cmp_deeply([map refaddr($_), keys %$map], bag(map refaddr($_), @input_keys[0, 2]), 'correct 2 keys remain');
    is_size_and_weakness($map, 2);
    is(keys(%$map), 2, 'map has 2 keys');
};

subtest 'exists' => sub {
    plan tests => 5;

    my $map = Data::WeakMap->new;

    note 'inserting 100 keys';
    my @input_keys = map { [$_ * 10] } (1 .. 100);
    @$map{@input_keys} = (201 .. 300);
    is_size_and_weakness($map, 100);

    ok(exists $map->{$input_keys[50]}, 'exists $map->{50th input} returns true');
    is_size_and_weakness($map, 100);

    my $foreign_object = [50];
    ok(! exists $map->{$foreign_object}, 'exists $map->{new foreign object} returns false');
    is_size_and_weakness($map, 100);
};

subtest 'scalar' => sub {
    plan tests => 2;

    my $map = Data::WeakMap->new;

    note 'inserting 100 elements';
    my @input_keys = map { [$_ * 10] } (1 .. 100);
    @$map{@input_keys} = (201 .. 300);

    my $_values_hashref = underlying_structure($map)->{values};
    is(scalar(%$map), scalar(%$_values_hashref), 'scalar(%$map) = scalar(%some_underlying_structure)');

    is_size_and_weakness($map, 100);
};

subtest 'boolean' => sub {
    plan tests => 6;

    my $map = Data::WeakMap->new;

    ok((keys %$map) ? 0 : 1, 'boolean(keys of empty map) == 0');
    ok((%$map) ? 0 : 1,      'boolean(empty map) == 0');
    ok($map ? 1 : 0,        'boolean(empty map reference) == 1');

    my @input_keys = map { [$_ * 10] } (1 .. 10);
    @$map{@input_keys} = (201 .. 210);

    ok((keys %$map) ? 1 : 0, 'boolean(keys of non-empty map) == 1');
    ok((%$map) ? 1 : 0,      'boolean(non-empty map) == 1');
    ok($map ? 1 : 0,        'boolean(non-empty map reference) == 1');
};

TODO: {
    local $TODO = "can't do it now, because the each function will automatically unweaken the keys for some reason";

    subtest 'attempt to do partial iteration with "each"' => sub {
        plan tests => 3;
        # plan tests => 1;

        for my $context (qw/ void scalar list /) {
        # for my $context (qw/ void /) {
            subtest "testing the 'each' function in $context context, with a new map" => sub {
                plan tests => 5;

                my $map = Data::WeakMap->new;
                note 'entering a block';
                {
                    safe_is_size_and_weakness($map, 0);

                    note 'inserting 100 lexically-scoped keys';
                    my @keys1 = map {[]} (1 .. 100);
                    @$map{@keys1} = (101 .. 200);
                    safe_is_size_and_weakness($map, 100);

                    note "calling the 'each' function on the map 40 times, in $context context";
                    if ($context eq 'void') {
                        each(%$map) for 1 .. 40;
                    }
                    elsif ($context eq 'scalar') {
                        my $foo;
                        $foo = each(%$map) for 1 .. 40;
                    }
                    elsif ($context eq 'list') {
                        my @foo;
                        @foo = each(%$map) for 1 .. 40;
                    }

                    safe_is_size_and_weakness($map, 100);

                    note 'exiting block';
                }
                safe_is_size_and_weakness($map, 0);
                is_size_and_weakness($map, 0);
            };
        }
    };
}

subtest 'clear' => sub {
    plan tests => 3;

    my $map = Data::WeakMap->new;

    my @keys_values = map { [] } (1 .. 10);

    %$map = @keys_values[0 .. 9];
    safe_is_size_and_weakness($map, 5);

    %$map = @keys_values[0 .. 5];
    safe_is_size_and_weakness($map, 3);
    is_size_and_weakness($map, 3);
};

done_testing;
