package WWW::Curl::Simple::Request;


use Moose;
use WWW::Curl::Easy;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use namespace::clean -except => 'meta';


has 'body' => (is => 'rw', isa => 'Str', required => 0, default => '');
has 'head' => (is => 'rw', isa => 'Str', required => 0, default => '');

has 'request' => (is => 'ro', isa => 'HTTP::Request');

has 'easy' => (is => 'rw', isa => 'WWW::Curl::Easy', required => 0, lazy_build => 1);

sub _build_easy {
    my ($self) = @_;
    
    my $req = $self->request;
    # return ourselves as a WWW::Curl::Easy-object?
    

    my $curl = new WWW::Curl::Easy;
    
    $curl->setopt(CURLOPT_HEADER,1);
    $curl->setopt(CURLOPT_NOPROGRESS,1);
    
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

sub response {
    my ($self) = @_;
    return HTTP::Response->parse($self->head . $self->body);
}
1;