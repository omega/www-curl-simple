#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    $curl->add_request(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));
    $curl->add_request(HTTP::Request->new(GET => 'http://www.yahoo.com'));
    
    my @res = $curl->perform;
    
    foreach my $res (@res) {
        isa_ok($res, "HTTP::Response");
        ok($res->is_success, "we have success!  " . $res->code);
    }
    
}


