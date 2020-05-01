#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use MIME::Base64;

# Do not check SSL certificate
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my ($hostname, $auth_token);

GetOptions (    "hostname=s"    => \$hostname,
                "token=s"       => \$auth_token,
) or die("Error in command line arguments\n");

if (!(defined $hostname) || !(defined $auth_token)) {
        print "UNKNOWN - Options not set properly.";
        exit 3;
}

# Get Token
my $url = "https://$hostname/cloudapi/1.0.0/sessions/provider";

my $header = [	'Accept'	=> 'application/json;version=33.0',
		'Authorization'	=> "Basic $auth_token",];

my $ua  = LWP::UserAgent->new;
my $request = HTTP::Request->new('POST', $url, $header);

my $content = $ua->request($request) or die "Cannot connect to $url: $_";

my $token = $content->{'_headers'}->{'x-vmware-vcloud-access-token'};

if (!(defined $token)) {
        print "ERROR - Cannot get token";
        exit 2;
}

# print "TOKEN : ".$token."\n";

# Get value

$url = "https://$hostname/cloudapi/1.0.0/cells";

$header = [	'Accept'        => 'application/json;version=33.0',
		'Authorization' => "Bearer $token",];

$request = HTTP::Request->new('GET', $url, $header);
$content = $ua->request($request) or die "Cannot connect to $url: $_";

my $result = $content->{'_content'} or die "No content in web page_ $_";

# Convert result to JSON
$result = decode_json($result) or die "Caught JSON::XS decode error: $_";

my $index = 0;
my $errors = 0;
my $output = '';

while ($index < $result->{'resultTotal'}) {
	my $name = $result->{'values'}[$index]->{'name'};
	my $value = $result->{'values'}[$index]->{'isActive'};
	my $display_value = 'active';
	if ($value < 1) {
		$errors++;
		$display_value = 'inactive';
	}

	$output .= " / " if ($index > 0); 
	$output .= "$name is $display_value";	


	$index++;
}

print $output;

exit 2 if ($errors > 0);
exit 0;

1;
