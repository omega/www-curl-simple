package WWW::Curl::Simple;

use Mouse;

use HTTP::Request;
use HTTP::Response;
use Carp qw/croak carp/;
use WWW::Curl::Simple::Request;
use WWW::Curl::Multi;
use WWW::Curl::Easy;

use Time::HiRes qw/usleep/;


#use base 'LWP::Parallel::UserAgent';

use namespace::clean -except => 'meta';

=head1 NAME

WWW::Curl::Simple - A simpler interface to WWW::Curl

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::Curl::Simple;

    my $curl = WWW::Curl::Simple->new();
    
    my $res = $curl->get('http://www.google.com/');


=cut

our $VERSION = '0.05';


=head3 request($req)

$req should be a  HTTP::Request object.

If you have a URI-string or object, look at the get-method instead

=cut

sub request {
    my ($self, $req) = @_;
    
    my $curl = WWW::Curl::Simple::Request->new(request => $req);
    
    # Starts the actual request
    return $curl->perform;
}


=head3 get($uri || URI)

Accepts one parameter, which should be a reference to a URI object or a
string representing a uri.

=cut

sub get {
    my ($self, $uri) = @_;
    return $self->request(HTTP::Request->new(GET => $uri));
}

=head3 post($uri || URI, $form)

Created a HTTP::Request of type POST to $uri, which can be a string
or a URI object, and sets the form of the request to $form. See
L<HTTP::Request> for more information on the format of $form

=cut

sub post {
    my ($self, $uri, $form) = @_;
    
    return $self->request(HTTP::Request->new(POST => $uri, undef, $form));
}

=head2 MULTI requests usage

=head3 add_request($req)

Adds $req (HTTP::Request) to the list of URL's to fetch

=cut

has requests => (
    is => 'ro', 
    isa => 'HashRef', 
    auto_deref => 1,
    default => sub { {} },
);

has '_multi' => (
    is => 'ro',
    isa => 'WWW::Curl::Multi',
    lazy_build => 1,
);
sub _build__multi {
    return WWW::Curl::Multi->new;
}
sub number_of_requests {
    my ($self) = @_;
    
    return scalar(keys(%{ $self->requests }));
}
sub add_request {
    my ($self, $req) = @_;

    my $i = $self->number_of_requests;
    
    
    my $real_req = WWW::Curl::Simple::Request->new(request => $req);
    
    $self->_fix_simple($real_req);
    
    $real_req->easy->setopt(CURLOPT_PRIVATE, $i);

    $self->requests->{$i} = $real_req;
    
    $self->_multi->add_handle($real_req->easy);
    
    $self->_multi->perform();
    
}
sub _fix_simple {
    my ($self, $req) = @_;
 
    my $curl = $req->easy;
    # we set this so we have the ref later on
    
    # here we also mangle all requests based on options
    # XXX: Should re-factor this to be a metaclass/trait on the attributes,
    # and a general method that takes all those and applies the propper setopt
    # calls
    if ($self->timeout_ms) {
        $curl->setopt(CURLOPT_TIMEOUT_MS, $self->timeout_ms) if $self->timeout_ms;
        $curl->setopt(CURLOPT_CONNECTTIMEOUT_MS, $self->connection_timeout_ms) if $self->connection_timeout_ms;            
    } else {
        $curl->setopt(CURLOPT_TIMEOUT, $self->timeout) if $self->timeout;
        $curl->setopt(CURLOPT_CONNECTTIMEOUT, $self->connection_timeout) if $self->connection_timeout;
    }
    
}
sub register {
    add_request(@_);
}

=head3 perform

Does all the requests added with add_request, and returns a 
list of HTTP::Response-objects

=cut

sub perform {
    my ($self) = @_;
    
    my $curlm = $self->_multi;
    
    my %reqs;
    my $i = $self->number_of_requests;
    my @res;
    while ($i) {
        my $active_transfers = $curlm->perform;
        if ($active_transfers != $i) {
            while (my ($id,$retcode) = $curlm->info_read) {
                if (defined($id)) {
                    $i--;
                    my $req = $self->requests->{$id};
                    unless ($retcode == 0) {
                        my $err = "Error during handeling of request: " 
                            .$req->easy->strerror($retcode)." ". $req->request->uri;
                        
                        croak($err) if $self->fatal;
                        carp($err) unless $self->fatal;
                    }
                    push(@res, $req);
                    delete($self->requests->{$id});
                    warn "handeled a request for " . $req->request->uri;
                }
            }
        }
        
        usleep(50_000);
        
    }
    return @res;
}


=head3 LWP::Parallel::UserAgent compliant methods

=over

=item wait

These methods are here to provide an easier transition from
L<LWP::Parallel::UserAgent>. It is by no means a drop in replacement,
but using C<wait> instead of C<perform> makes the return-value perform
more alike

=back
=cut

sub wait {
    my $self = shift;
    
    my @res = $self->perform(@_);
    
    # convert to a hash
    my %res;
    
    while (my $r = pop @res) {
        #warn "adding $r at " . scalar(@res);
        $res{scalar(@res)} = $r;
    }
    
    return \%res;
}


=head2 ATTRIBUTES

=head3 timeout / timeout_ms

Sets the timeout of individual requests, in seconds or milliseconds

=cut

has 'timeout' => (is => 'ro', isa => 'Int');
has 'timeout_ms' => (is => 'ro', isa => 'Int');

=head3 connection_timeout /connection_timeout_ms

Sets the timeout of the connect phase of requests, in seconds or milliseconds

=cut

has 'connection_timeout' => (is => 'ro', isa => 'Int');
has 'connection_timeout_ms' => (is => 'ro', isa => 'Int');


=head3 fatal

Defaults to true, but if set to false, it will make failure in multi-requests
warn instead of die.

=cut

has 'fatal' => (is => 'ro', isa => 'Bool', default => 1);

=head1 AUTHOR

Andreas Marienborg, C<< <andreas at startsiden.no> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-curl-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Curl-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Curl::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Curl-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Curl-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Curl-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Curl-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Andreas Marienborg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__->meta->make_immutable;

no Moose;
 
1; # End of WWW::Curl::Simple
