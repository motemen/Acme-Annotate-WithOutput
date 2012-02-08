use inc::Module::Install;

name 'Acme-Annotate-WithOutput';
all_from 'lib/Acme/Annotate/WithOutput.pm';

requires 'parent';
requires 'Symbol';
requires 'Scalar::Util';
requires 'Tie::Handle';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'File::Temp';

auto_set_repository;
auto_include;

WriteAll;
