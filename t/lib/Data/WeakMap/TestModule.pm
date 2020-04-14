package Data::WeakMap::TestModule;
use strict;
use warnings FATAL => 'all';

my $CLASS = __PACKAGE__;

use parent 'Test::Builder::Module';
use Test::Builder; # TODO: remove if not needed
use Scalar::Util 'isweak';
use Exporter 'import'; # TODO: check if this is safe for v5.16
our @EXPORT_OK = qw/ safe_is_size_and_weakness is_size_and_weakness /;

sub safe_is_size_and_weakness {
    my ($map, $desired_size) = @_;

    my $tb = $CLASS->builder;

    my $struct = ${ tied(%$map)->[0] };
    my $keys = $struct->{keys};
    my $values = $struct->{values};
    my $triggers = $struct->{triggers};

    $tb->subtest("(safe mode): underlying structure is weak, and \%\$values (the only size test done) has size $desired_size" => sub {
        $tb->level(4);

        my $fail = 0;

        my @props = keys %$values;

        $fail = 1 if @props != $desired_size;
        $fail = 1 if scalar(grep { ! isweak($keys->{$_})          } @props);
        $fail = 1 if scalar(grep { ! isweak(${ $triggers->{$_} }) } @props);

        if (!! $fail) {
            $tb->is_eq(scalar(@props), $desired_size, "\%\$values (partial check) has the right size ($desired_size)");
            $tb->is_eq(scalar(grep {! isweak($keys->{$_})}           @props), 0, 'number of strong keys in %$keys (0)');
            $tb->is_eq(scalar(grep {! isweak(${ $triggers->{$_} }) } @props), 0, 'number of strong keys in %$triggers (0)');
        } else {
            $tb->ok(1, 'pass');
        }

        $tb->done_testing($fail ? 3 : 1);
    });
}

sub is_size_and_weakness {
    my ($map, $desired_size) = @_;

    my $tb = $CLASS->builder;

    my $struct = ${ tied(%$map)->[0] };
    my $keys = $struct->{keys};
    my $values = $struct->{values};
    my $triggers = $struct->{triggers};

    $tb->subtest("underlying structure is weak and has size $desired_size (can affect 'each')" => sub {
        $tb->level(4);

        my $fail = 0;

        # test 1: check sizes of all three underlying hashrefs
        $fail = 1 if scalar(grep {keys(%$_) != $desired_size} ($keys, $values, $triggers));

        # test 2: check weakness of keys in plain hashrefs %$keys & %$triggers
        $fail = 1 if scalar(grep {!isweak($_)}  values %$keys);
        $fail = 1 if scalar(grep {!isweak($$_)} values %$triggers);

        if (!! $fail) {
            $tb->is_eq(scalar(keys(%$keys)),     $desired_size, "\%\$keys has the right size ($desired_size)"    );
            $tb->is_eq(scalar(keys(%$values)),   $desired_size, "\%\$values has the right size ($desired_size)"  );
            $tb->is_eq(scalar(keys(%$triggers)), $desired_size, "\%\$triggers has the right size ($desired_size)");

            $tb->is_eq(scalar(grep {!isweak($_)}  values %$keys),     0, 'number of strong keys in %$keys (0)');
            $tb->is_eq(scalar(grep {!isweak($$_)} values %$triggers), 0, 'number of strong keys in %$triggers (0)');
        } else {
            $tb->ok(1, 'pass');
        }

        $tb->done_testing($fail ? 5 : 1);
    });
}

1;
