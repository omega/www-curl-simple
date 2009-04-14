#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;
use WWW::Curl::Simple;


my $curl = WWW::Curl::Simple->new();

{
    my $res = $curl->request(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));
    isa_ok($res, "HTTP::Response");
    ok($res->is_success, "request suceeded");
    like($res->content, qr/Wikipedia/);
    isa_ok($res->request, "HTTP::Request");
    
}
{
    my $res = $curl->get('http://www.google.com/');
    isa_ok($res, "HTTP::Response");
    unlike($res->content, qr|^HTTP/1|);
    isa_ok($res->request, "HTTP::Request");
    #like($res->content, qr|^<HTML>|);
    is($res->content_type, "text/html");
    
}


{
    # Test POST
    my $form = 's=jennifer+aniston';
    my $res = $curl->post('http://wap.1881.no/?i=4854&showonly=1', $form);
    unless(ok($res->is_success, "request succeeded")) {
        diag($res->code . " " . $res->status_line);
    }
    isa_ok($res->request, "HTTP::Request");
    
}