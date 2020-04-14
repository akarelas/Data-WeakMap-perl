requires 'perl', '5.016'; # need access to the ${^GLOBAL_PHASE} var, etc

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Deep'; # TODO: find minimum version for this
};

requires 'Scalar::Util';
requires 'Carp';

requires 'Sentinel';

# TODO: remove this before release
requires 'Devel::Confess';
