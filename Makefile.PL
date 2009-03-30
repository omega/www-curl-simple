use inc::Module::Install;

name     'WWW-Curl-Simple';
all_from 'lib/WWW/Curl/Simple.pm';
author   'Andreas Marienborg <andreas@startsiden.no>';
license  'perl';

build_requires 'Test::More';

requires 'WWW::Curl' => '4.0';


auto_install;

WriteAll;

