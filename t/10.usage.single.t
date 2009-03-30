#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    my $res = $curl->request(HTTP::Request->new(GET => 'http://www.google.com/ncr'));
    isa_ok($res, "HTTP::Response");
    is($res->code, 302, "request suceeded");
    is($res->header("Location"), "http://www.google.com/");
}
{
    my $res = $curl->get('http://www.google.com/');
    isa_ok($res, "HTTP::Response");
}


