requires 'perl', '5.014'; # need access to the ${^GLOBAL_PHASE} var

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Deep'; # TODO: find minimum version for this
};

requires 'Scalar::Util';
requires 'Carp';
