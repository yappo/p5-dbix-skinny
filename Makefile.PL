use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Digest::SHA1';
requires 'DBI';

use_test_base;
build_requires 'Test::More';
build_requires 'Test::Declare';

auto_include;
WriteAll;
