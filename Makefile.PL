use inc::Module::Install;
name 'AnyEvent-FileWatch';
all_from 'lib/AnyEvent/FileWatch.pm';

requires 'AnyEvent';
requires 'File::Zglob';
requires 'AnyEvent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
