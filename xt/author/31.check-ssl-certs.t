#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use WWW::Curl::Simple;

my $url = 'https://google.co.uk/robots.txt';
my $curl;
my $response;

{
    $curl     = WWW::Curl::Simple->new(check_ssl_certs => 1);
    eval { $response = $curl->get($url); };
    ok($@ && !defined($response));
}

{
    $curl     = WWW::Curl::Simple->new(check_ssl_certs => 0);
    eval { $response = $curl->get($url); };
    ok(!$@ && defined($response) && $response->code == 200);
}

{
    # default is 0 (i.e. don't check), so this should work too
    $curl     = WWW::Curl::Simple->new();
    $response = $curl->get($url);
    ok(!$@ && defined($response) && $response->code == 200);
}

