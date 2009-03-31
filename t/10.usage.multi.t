#!/usr/bin/perl -w

use strict;
use Test::More;
use WWW::Curl::Simple;

my @urls = (
'http://en.wikipedia.org/wiki/Main_Page',
'http://www.yahoo.com',
'http://www.startsiden.no',
'http://www.abcnyheter.no',
'http://www.cnn.com',
'http://www.bbc.co.uk',
'http://www.vg.no',
'http://www.perl.org',
'http://www.perl.com',
);

plan tests => scalar(@urls) * 2;

my $curl = WWW::Curl::Simple->new();

{
    $curl->add_request(HTTP::Request->new(GET => $_)) foreach (@urls);
    
    my @res = $curl->perform;
    
    foreach my $res (@res) {
        isa_ok($res, "HTTP::Response");
        ok($res->is_success, "we have success!  " . $res->code);
    }
    
}


