use inc::Module::Install;

name 'Acme-Annotate-WithResult';
all_from 'lib/Acme/Annotate/WithResult.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

WriteAll;
