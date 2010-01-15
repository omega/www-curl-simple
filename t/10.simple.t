#!/usr/bin/perl -w

use strict;
use Test::More;
use WWW::Curl::Simple;

use t::Testserver;

my @urls = (
'http://localhost:3516',
);


my $pid = fork();

if (not defined $pid) {
    plan skip_all => "Fork not supported";
} elsif ($pid == 0) {
    ## In the child, do requests here?
    plan tests => 2;
    
    sleep(1);
    
    my $curl = WWW::Curl::Simple->new(timeout => 1);
    is($curl->timeout, 1);
    my $res = $curl->request(HTTP::Request->new(GET => 'http://localhost:3516'));

    is($res->content, "OK");
} else {
    ## in the parent
    my $serv = TestServer->new({ port => 3516, log_level => 0 });
    
    $serv->run;
    
    
    waitpid($pid, 0);
}