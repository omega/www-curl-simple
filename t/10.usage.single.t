#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    my $res = $curl->request(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));
    isa_ok($res, "HTTP::Response");
    ok($res->is_success, "request suceeded");
    like($res->content, qr/Wikipedia/);
}
{
    my $res = $curl->get('http://www.google.com/');
    isa_ok($res, "HTTP::Response");
}


