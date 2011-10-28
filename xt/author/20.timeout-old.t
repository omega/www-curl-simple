#!/usr/bin/perl -w

use strict;
use lib qw(/Users/andremar/local/src/WWW-Curl-4.11/blib/lib);
use Test::More;
use Test::Exception;
use WWW::Curl::Simple;



my @urls = (
'http://localhost:3516',
);


my $pid = fork();

if (not defined $pid) {
    plan skip_all => "Fork not supported";
} elsif ($pid == 0) {
    ## In the child, do requests here?
    plan tests => 3;
    
    sleep(1);
    
    {
        my $curl = WWW::Curl::Simple->new(timeout => 1);
        is($curl->timeout, 1);
        {
            $curl->add_request(HTTP::Request->new(GET => $_)) foreach (@urls);

            throws_ok { $curl->perform } qr/timeout was reached/i, "We throw proper timeout error";

        }
        
    }
    
    {
        my $curl = WWW::Curl::Simple->new(timeout_ms => 1);
        {
            $curl->add_request(HTTP::Request->new(GET => $_)) foreach (@urls);
            
            throws_ok { $curl->perform } qr/(timeout was reached|use timeout_ms)/i,
                "We throw one of two proper exceptions";
                
        }
    }
    
} else {
    ## in the parent
    my $serv = TestServer->new({ port => 3516, log_level => 0 });
    
    $serv->run;
    
    
    waitpid($pid, 0);
}


package TestServer;

use strict;
use base qw(Net::Server::Single);

sub process_request {
    my $self = shift;
    
    sleep 5;
    exit(0);
}
1;
