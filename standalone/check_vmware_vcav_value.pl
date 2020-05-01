#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;

# Do not check SSL certificate
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my ($hostname, $login, $password, $lookup);

GetOptions (    "hostname=s"    => \$hostname,
                "login=s"       => \$login,
                "password=s"    => \$password,
                "lookup=s"      => \$lookup,
) or die("Error in command line arguments\n");

if (!(defined $hostname) || !(defined $login) || !(defined $password) || !(defined $lookup)) {
        print "UNKNOWN - Options not set properly.";
        exit 3;
}

# Get Token
my $url = "https://$hostname/sessions";

my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

my $data = {
        "type"          => "vcdCredentials",
        "vcdUser"       => $login,
        "vcdPassword"   => $password,
};

my $encoded_data = encode_json($data);

my $ua  = LWP::UserAgent->new;
my $request = HTTP::Request->new('POST', $url, $header, $encoded_data);

my $content = $ua->request($request) or die "Cannot connect to $url: $_";

my $token = $content->{'_headers'}->{'x-vcav-auth'};

if (!(defined $token)) {
        print "ERROR - Cannot get token";
        exit 2;
}

#print "TOKEN : ".$token."\n";

# Get value

$url = "https://$hostname/diagnostics/health";
$header = ['X-VCAV-Auth' => $token];

$request = HTTP::Request->new('GET', $url, $header);
$content = $ua->request($request) or die "Cannot connect to $url: $_";

my $result = $content->{'_content'} or die "No content in web page_ $_";

# Convert result to JSON
$result = decode_json($result) or die "Caught JSON::XS decode error: $_";

if (defined($result->{$lookup})) {
        print "ERROR - Lookup value '$lookup' : $result->{$lookup}";
        exit 2;
} else {
        print "OK - Lookup value '$lookup' not found";
        exit 0;
}

1;
