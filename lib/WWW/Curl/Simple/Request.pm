package WWW::Curl::Simple::Request;

=head1 NAME

WWW::Curl::Simple::Request - A small class representing request/response

=head1 DESCRIPTION

Just a way to collect things used by both single and multi, and some
WWW::Curl setup. You shouldn't need to use this class anywhere, although
C<$curl->perform> returns objects of this class

=cut


use Moose;
use WWW::Curl::Easy;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use namespace::clean -except => 'meta';

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 agent

A String that will be sent as the user-agent string. Defaults to

=cut

has 'agent' => (is => 'rw', isa => 'Str', required => 0, lazy_build => 1);

sub _build_agent {
    return "WWW::Curl::Simple/" . $WWW::Curl::Simple::VERSION;
}

=head2 METHODS

=head3 body

The body of the response

=cut

has 'body' => (is => 'rw', isa => 'Str', required => 0, default => '');

=head3 head

The head of the response

=cut

has 'head' => (is => 'rw', isa => 'Str', required => 0, default => '');

=head3 request

The HTTP::Request-object that we where created with. 

=cut

has 'request' => (is => 'ro', isa => 'HTTP::Request');

=head3 easy

our WWW::Curl::Easy-object

=cut

has 'easy' => (is => 'rw', isa => 'WWW::Curl::Easy', required => 0, lazy_build => 1);

sub _build_easy {
    my ($self) = @_;
    
    my $req = $self->request;
    # return ourselves as a WWW::Curl::Easy-object?
    

    my $curl = new WWW::Curl::Easy;
    
    $curl->setopt(CURLOPT_NOPROGRESS,1);
    $curl->setopt(CURLOPT_USERAGENT, $self->agent);
    
    my $url = $req->uri->as_string;
    $curl->setopt(CURLOPT_URL, $url);
    if ($req->method eq 'POST') {
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $req->content);
    }
    
    my @headers;
    foreach my $h (+$req->headers->header_field_names) {
        #warn "h: $h";
        push(@headers, "$h: " . $req->header($h));
    }
    if (scalar(@headers)) {
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    }
    
    $curl->setopt(CURLOPT_HEADERFUNCTION, sub {
        my $chunk = shift;
        $self->head($self->head . $chunk);
        return length($chunk);
    });
    $curl->setopt(CURLOPT_WRITEFUNCTION, sub {
        my $chunk = shift;
        $self->body($self->body . $chunk);
        return length($chunk);
    });
    
    return $curl;
    
}

=head3 perform

Performs the actuall request trough WWW::Curl::Easy. Used mostly in
single request land. Will croak on errors.

=cut

sub perform {
    my ($self) = @_;
    
    my $retcode = $self->easy->perform;
    # Looking at the results...
    if ($retcode == 0) {
            return $self->response;
    } else {
            croak("An error happened: ".$self->easy->strerror($retcode)." ($retcode)\n");
    }
    
}

=head3 response

Returns a HTTP::Response that represents the response of this object.

Also sets request on the response object to the original request object.

=cut

sub response {
    my ($self) = @_;
    my $res = HTTP::Response->parse($self->head . "\r" . $self->body);
    $res->request($self->request);
    $res->content($self->body);
    return $res;
}

=head1 COPYRIGHT & LICENSE

Copyright 2009 Andreas Marienborg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;