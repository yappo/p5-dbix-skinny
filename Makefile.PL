use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';

build_requires 'Test::More';
build_requires 'Test::Declare';

use_test_base;
auto_include;
WriteAll;
