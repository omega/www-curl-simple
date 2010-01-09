package WWW::Curl::Simple;

use Moose;

use HTTP::Request;
use HTTP::Response;
use Carp qw/croak/;
use WWW::Curl::Simple::Request;
use WWW::Curl::Multi;
use WWW::Curl::Easy;
use Sub::Alias;

use namespace::clean -except => 'meta';

=head1 NAME

WWW::Curl::Simple - A simpler interface to WWW::Curl

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::Curl::Simple;

    my $curl = WWW::Curl::Simple->new();
    
    my $res = $curl->get('http://www.google.com/');


=cut

our $VERSION = '0.01';


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

sub post {
    my ($self, $uri, $form) = @_;
    
    return $self->request(HTTP::Request->new(POST => $uri, undef, $form));
}

=head2 MULTI requests usage

=head3 add_request($req)

Adds $req (HTTP::Request) to the list of URL's to fetch

=cut

has _requests => (
    traits => ['Array'], 
    is => 'ro', 
    isa => 'ArrayRef[WWW::Curl::Simple::Request]', 
    handles => {
        _add_request => 'push',
        requests => 'elements',
        _find_request => 'first',
        _count_requests => 'count',
        _get_request => 'get',
        _delete_request => 'delete',
    },
    default => sub { [] },
);

alias register => 'add_request';
sub add_request {
    my ($self, $req) = @_;
    $req = WWW::Curl::Simple::Request->new(request => $req);
    $self->_add_request($req);
    
    return $req;
}

=head3 has_request $request

Will return true if $request is one of our requests

=cut

sub has_request {
    my ($self, $req) = @_;
    
    $self->_find_request(sub {
        $_ == $req
    });
}

=head3 delete_request $req

Will remove $req from our list of requests

=cut

sub delete_request {
    my ($self, $req) = @_;
    
    return unless $self->has_request($req);
    # need to find the index
    my $c = $self->_count_requests;
    
    while ($c--) {
        $self->_delete_request($c) if ($self->_get_request($c) == $req);
    }
    return 1;
}

=head3 perform

Does all the requests added with add_request, and returns a 
list of HTTP::Response-objects

=cut
alias wait => 'perform';

sub perform {
    my ($self) = @_;
    
    my $curlm = WWW::Curl::Multi->new;
    
    my %reqs;
    my $i = 0;
    foreach my $req ($self->requests) {
        $i++;
        my $curl = $req->easy;
        # we set this so we have the ref later on
        $curl->setopt(CURLOPT_PRIVATE, $i);
        $curlm->add_handle($curl);
        
        $reqs{$i} = $req;
    }
    my @res;
    while ($i) {
        my $active_transfers = $curlm->perform;
        if ($active_transfers != $i) {
            while (my ($id,$retcode) = $curlm->info_read) {
                if ($id) {
                    $i--;
                    my $req = $reqs{$id};
                    
                    unless ($retcode == 0) {
                        croak("Error during handeling of request: " .$req->easy->strerror($retcode)." ". $req->request->uri);
                    }
                    push(@res, $req->response);
                    delete($reqs{$id});
                }
            }
        }
    }
    return @res;
}

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

1; # End of WWW::Curl::Simple
