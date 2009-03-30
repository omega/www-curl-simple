#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    $curl->add_request(HTTP::Request->new(GET => 'http://www.google.com'));
    $curl->add_request(HTTP::Request->new(GET => 'http://www.yahoo.com'));
    
    my @res = $curl->perform;
    
    foreach my $res (@res) {
        isa_ok($res, "HTTP::Response");
    }
    
}


