#!/usr/bin/env perl
use 5.016;
use warnings FATAL => 'all';
use lib "lib", "local/lib/perl5";
use Benchmark 'countit';
use Time::HiRes;

use Data::WeakMap;

STDOUT->autoflush;

sub test {
    my ($name, $code, $loop_size) = @_;
    $loop_size //= 1;

    my $initializing_code = $code;

    say '';
    say "--------------------------- TEST: $name ---------------------------";

    print "initializing (" . localtime . ")... ";
    my $t0 = Time::HiRes::time;
    my $test_code = $initializing_code->();
    my $duration = Time::HiRes::time - $t0;
    say 'done (', sprintf("%.1f", $duration), ' sec)';
    say '';

    print "starting benchmark tests (" . localtime . ")... ";
    $t0 = Time::HiRes::time;
    my $t = countit(5, $test_code);
    $duration = Time::HiRes::time - $t0;
    say "done (", sprintf("%.1f", $duration), " sec)";
    say '';

    say 'Results based on: (iterations: ', $t->iters, ', ', 'cpu time: ', $t->cpu_a, ')';
    say '';
    my $speed = int($t->iters / $t->cpu_a);
    say $speed, ' iterations / second', ($loop_size != 1 ? " (with a loop size of $loop_size)" : "");
    my $human_readable = '';
    $speed *= $loop_size;
    if ($speed >= 1000) { $speed /= 1000; $human_readable = 'k'; }
    if ($speed >= 1000) { $speed /= 1000; $human_readable = 'm'; }
    say "--------------------------- $name: ", sprintf("%.1f", $speed) ,"$human_readable/s ---------------------------";
    say '' for 1 .. 2;
}


################################ TEST CODE STARTS HERE ################################


if (0) {{
    say "\n-- DUMMY TESTS --\n\n";

    test("create refs", sub {
        my $foo;
        say 'sleeping 1 sec';
        sleep(1);
        say '  slept, starting tests';

        sub {
            $foo = {} for 1 .. 10e3;
        }
    }, 10e3);
}}

# test 1:
test("just inserts (map)", sub {

    my $map = Data::WeakMap->new;
    my @keys = map {[]} (1 .. 10_000_000);
    my $i = 0;

    sub {
        $map->{ $keys[$i++] } = 5;
    }

});

# test 1b:
test("just inserts (hash)", sub {

    my $map = {};
    my @keys = map {[]} (1 .. 20_000_000);
    my $i = 0;

    sub {
        $map->{ $keys[$i++] } = 5;
    }

});


# test 2:
test("inserts/retrieves in 1:10 ratio, without misses (map)", sub {

    my $map = Data::WeakMap->new;
    my @keys = map {[]} (1 .. 20_000_000);
    my $i = 0;
    my $foo;

    sub {
        if ($i++ < 100 or rand() < 0.9) {
            $map->{ $keys[$i] } = 5;
        } else {
            $foo = $map->{ $keys[ int rand $i ] }
        }
    }

});

# test 2b:
test("inserts/retrieves in 1:10 ratio, without misses (hash)", sub {

    my $map = {};
    my @keys = map {[]} (1 .. 20_000_000);
    my $i = 0;
    my $foo;

    sub {
        if ($i++ < 100 or rand() < 0.9) {
            $map->{ $keys[$i] } = 5;
        } else {
            $foo = $map->{ $keys[ int rand $i ] }
        }
    }

});


# test 3:
test("inserts/retrieves in 1:10 ratio, with 50% misses (map)", sub {

    my $map = Data::WeakMap->new;
    my @keys = map {[]} (1 .. 20_000_000);
    my $i = 0;
    my $rand;
    my $foo;

    sub {
        $rand = rand();
        if ($i++ < 100 or $rand < 0.9) {
            $map->{ $keys[$i] } = 5;
        } elsif ($rand < 0.545) {
            $foo = $map->{ $keys[ int rand $i ] }
        } else {
            $foo = $map->{ $keys[ $i + 10_000_000 ] };
        }
    }

});

# test 3b:
test("inserts/retrieves in 1:10 ratio, with 50% misses (hash)", sub {

    my $map = {};
    my @keys = map {[]} (1 .. 20_000_000);
    my $i = 0;
    my $rand;
    my $foo;

    sub {
        $rand = rand();
        if ($i++ < 100 or $rand < 0.9) {
            $map->{ $keys[$i] } = 5;
        } elsif ($rand < 0.545) {
            $foo = $map->{ $keys[ int rand $i ] }
        } else {
            $foo = $map->{ $keys[ $i + 10_000_000 ] };
        }
    }

});


__END__
# test 4
test("create & delete", initializer(0, $NOVALUES), '

    for (1 .. 100) {
        $foo = [];
        $map->{ $foo } = 5;
    }

', 100);
