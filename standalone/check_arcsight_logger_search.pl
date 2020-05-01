#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use HTTP::Request::Common;
use JSON::XS;
use LWP::UserAgent;
use POSIX qw(strftime);
use URI::Escape;

# Do not check SSL certificate
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my ($hostname, $login, $password);

GetOptions (    "hostname=s"    => \$hostname,
                "login=s"       => \$login,
                "password=s"    => \$password,
				"port=i"		=> \$port,
) or die("Error in command line arguments\n");

if (!(defined $hostname) || !(defined $login) || !(defined $password)) {
        print "UNKNOWN - Options not set properly.";
        exit 3;
}

# Get token
my $login_ua = new LWP::UserAgent;
my $login_content = $login_ua->request(POST "https://$hostname:$port/core-service/rest/LoginService/login?login=$login&password=".uri_escape($password));
my $login_result = $login_content->{'_content'} or die "No content in web page";

my $token;

if ($login_result =~ m/\<ns3\:return\>(\S+)\<\/ns3\:return\>/gi ) {
	$token = $1;
} else {
	print "Cannot get token.";
	exit 2;
}

#print "TOKEN : ".$token."\n";

# Initiate search
my $search_session_id = time();
my $start_time = strftime "%Y-%m-%dT%H:%M:%S.000Z", localtime(time() - 366*24*60*60);
my $end_time = strftime "%Y-%m-%dT%H:%M:%S.000Z", localtime(time());

#print "SEARCH SESSION ID : ".$search_session_id."\n";
#print "START TIME : ".$start_time."\n";
#print "END TIME : ".$end_time."\n";

my $search_url = "https://$hostname:$port/server/search";
my $search_header = ['Content-Type' => 'application/json; charset=UTF-8'];

my $search_data = {
        "search_session_id"	=> int($search_session_id),
        "user_session_id"	=> $token,
#        "query"			=> "deviceVendor = \"ArcSight\"",
	"query"			=> "_storageGroup NOT IN [\"Internal Event Storage Group\"]",
	"start_time"		=> $start_time,
	"end_time"		=> $end_time,
	"field_summary"		=> \1,
};

my $search_encoded_data = encode_json($search_data);

my $search_ua  = LWP::UserAgent->new;
my $search_request = HTTP::Request->new('POST', $search_url, $search_header, $search_encoded_data);
my $search_content = $search_ua->request($search_request) or die "Cannot connect to $search_url: $_";
my $search_result = $search_content->{'_content'} or die "No content in web page";

my $search_id;

if ($search_result =~ m/"sessionId"\:"(\d+)"/gi ) {
        $search_id = $1;
} else {
        print "Cannot get search ID.";
        exit 2;
}


#print "SEARCH ID : ".$search_id."\n";

# Wait for search to run
sleep 10;

# Get first date
my $events_url = "https://$hostname:$port/server/search/events";
my $events_header = ['Content-Type' => 'application/json; charset=UTF-8'];
my $events_data = {
	"search_session_id"     => int($search_session_id),
	"user_session_id"       => $token,
	"fields"		=> ["endTime", "deviceVendor", "deviceProduct", "name", "message"],
	"length"		=> 1,
};

my $events_encoded_data = encode_json($events_data);
my $events_ua  = LWP::UserAgent->new;
my $events_request = HTTP::Request->new('POST', $events_url, $events_header, $events_encoded_data);

my $events_content = $events_ua->request($events_request) or die "Cannot connect to $events_url: $_";
my $events_result = $events_content->{'_content'} or die "No content in web page";

# Convert reult to JSON
$events_result = decode_json($events_result) or die "Caught JSON::XS decode error: $_";

# Get values
my $event_date = strftime "%Y-%m-%d %H:%M:%S", localtime($events_result->{"results"}[0][1] / 1000);
my $event_name = $events_result->{"results"}[0][4];

print "First non internal event date : ".$event_date." / ".$event_name;

#print "FIRST DATE: ".$first_date."\n";

# Logout
my $logout_ua = new LWP::UserAgent;
my $logout_content = $logout_ua->request(POST "https://$hostname:$port/core-service/rest/LoginService/logout?authToken=$token");

exit 0;

1;
