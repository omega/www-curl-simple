#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    my $req = $curl->add_request(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));
    
    ok($curl->has_request($req), "We can check for existance of a request");
    
    isa_ok(
        $req,
        "WWW::Curl::Simple::Request", "We get the right index back from add_request",
    );
    isa_ok(
        $curl->add_request(HTTP::Request->new(GET => 'http://www.yahoo.com')),
        "WWW::Curl::Simple::Request", "We get the right index back from our second add_request",
    );
    
    my @res = $curl->perform;
    
    ok($curl->delete_request($req), "We can remove a request");
    is($curl->_count_requests, 1, "We have removed one request");
    foreach my $res (@res) {
        isa_ok($res, "HTTP::Response");
        ok($res->is_success or $res->is_redirect, "we have success for " . $res->base . "!  " . $res->status_line);
    }
    
}


