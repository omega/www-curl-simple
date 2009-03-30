package WWW::Curl::Simple;

use Moose;
use MooseX::AttributeHelpers;

use HTTP::Request;
use HTTP::Response;
use Carp qw/croak/;
use WWW::Curl::Easy;
use WWW::Curl::Multi;

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

has '_multi' => (is => 'ro', isa => 'WWW::Curl::Multi', lazy_build => 1);
sub _build__multi {
    my ($self) = @_;
    
    return WWW::Curl::Multi->new;
}

sub _get_easy {
    my ($self, $req) = @_;
    
    my $curl = new WWW::Curl::Easy;
    
    $curl->setopt(CURLOPT_HEADER,1);
    $curl->setopt(CURLOPT_NOPROGRESS,1);
    
    $curl->setopt(CURLOPT_URL, $req->uri);
    if ($req->method eq 'POST') {
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $req->content);
    }
    
    my @headers;
    foreach my $h (+$req->headers->header_field_names) {
        warn "h: $h";
        push(@headers, "$h: " . $req->header($h));
    }
    if (scalar(@headers)) {
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    }
    
    return $curl;
}

=head3 request($req)

$req should be a  HTTP::Request object.

If you have a URI-string or object, look at the get-method instead

=cut

sub request {
    my ($self, $req) = @_;
    
    my $curl = $self->_get_easy($req);
    
    my ($body, $head);
    # NOTE - do not use a typeglob here. A reference to a typeglob is okay though.
    open (my $fileb, ">", \$body);
    open (my $fileh, ">", \$head);
    $curl->setopt(CURLOPT_WRITEDATA, $fileb);
    $curl->setopt(CURLOPT_WRITEHEADER, $fileh);
    
    # Starts the actual request
    my $retcode = $curl->perform;

    # Looking at the results...
    if ($retcode == 0) {
            return HTTP::Response->parse($head . $body);
    } else {
            croak("An error happened: ".$curl->strerror($retcode)." ($retcode)\n");
    }
}


=head3 get($uri || URI)

Accepts one parameter, which should be a reference to a URI object or a
string representing a uri.

=cut

sub get {
    my ($self, $uri) = @_;
    return $self->request(HTTP::Request->new(GET => $uri));
}

=head2 MULTI requests usage

=head3 add_request($req)

Adds $req (HTTP::Request) to the list of URL's to fetch

=cut

has _requests => (
    metaclass => 'Collection::Array', 
    is => 'ro', 
    isa => 'ArrayRef[WWW::Curl::Easy]', 
    provides => {
        push => '_add_request',
        elements => 'requests'
    },
);

sub add_request {
    my ($self, $req) = @_;
    
    #convert $req into WWW::Curl::Easy;
    
}
=head3 perform

Does all the requests added with add_request, and returns a 
list of HTTP::Response-objects

=cut

sub perform {
    my ($self) = @_;
    
    
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
