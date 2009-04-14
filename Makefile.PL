use inc::Module::Install;

name     'WWW-Curl-Simple';
all_from 'lib/WWW/Curl/Simple.pm';
author   'Andreas Marienborg <andreas@startsiden.no>';
license  'perl';

build_requires 'Test::More';

requires 'WWW::Curl' => '4.06';
requires 'Moose' => '0.50';
requires 'MooseX::AttributeHelpers';
requires 'Sub::Alias';
requires 'HTTP::Request';
requires 'namespace::clean';

auto_install;

WriteAll;

