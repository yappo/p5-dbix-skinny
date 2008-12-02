use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Class::Data::Inheritable';
requires 'Module::Find';
requires 'Digest::SHA1';
requires 'Class::Accessor::Fast';
requires 'DBI';
requires 'Sub::Install';
requires 'Class::Trigger';
requires 'SQL::Parser';

use_test_base;
build_requires 'Test::More';
build_requires 'Test::Declare';

auto_include;
WriteAll;
