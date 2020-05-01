#!/usr/bin/php
<?php

$url = "https://api.pingdom.com/api/2.1/checks";
$login = "LOGIN";
$password = "PASSWORD";
$key = "KEY";

if (isset($argv[1])) {
        $id = $argv[1];
} else {
        print "UNKNOWN : ID is not set\n";
        exit(3);
}

$id = $argv[1];
$latence = $argv[2];

# Init cURL
$curl = curl_init();
# Set target URL
curl_setopt($curl, CURLOPT_URL, $url."/".$id);
# Set the desired HTTP method (GET is default, see the documentation for each request)
curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "GET");
# Set user (email) and password
curl_setopt($curl, CURLOPT_USERPWD, $login.":".$password);
# Add a http header containing the application key (see the Authentication section of this document)
curl_setopt($curl, CURLOPT_HTTPHEADER, array("App-Key: ".$key));
# Ask cURL to return the result as a string
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);


# Execute the request and decode the json result into an associative array
$response = json_decode(curl_exec($curl),true);

# Check for errors returned by the API
if (isset($response['error'])) {
        print "CRITICAL : ".$response['error']['errormessage']."\n";
        exit(2);
}

# Fetch the list of checks from the response
$check = $response['check'];

#print "ID : ".$check['id']."\n";
#print "Name : ".$check['name']."\n";
#print "Hostname : ".$check['hostname']."\n";
#print "Last response time : ".$check['lastresponsetime']."\n";
#print "Status : ".$check['status']."\n";

# Check status
if ($check['status'] == 'up' && $check['lastresponsetime'] < $latence) {
        print "OK : ".$check['name']." (".$check['hostname'].") is UP | time=".$check['lastresponsetime']."\n";
        exit(0);
} else if ($check['status'] == 'down' || $check['lastresponsetime'] > $latence) {
        if ($check['status'] == 'down')
                print "CRITICAL : ".$check['name']." (".$check['hostname'].") is DOWN | time=".$check['lastresponsetime']."\n";
        else if($check['lastresponsetime'] > $latence)
                print "CRITICAL : ".$check['name']." (".$check['hostname'].") Response time ".$check['lastresponsetime']." ms | time=".$check['lastresponsetime']."\n";
        exit(2);
} else if ($check['status'] == 'unconfirmed_down' || $check['lastresponsetime'] > $latence) {
        print "CRITICAL : ".$check['name']." (".$check['hostname'].") is UNCONFIRMED DOWN | time=".$check['lastresponsetime']."\n";
        exit(2);
} else if ($check['status'] == 'unknown') {
        print "UNKNOWN : ".$check['name']." (".$check['hostname'].") is UNKNOWN | time=".$check['lastresponsetime']."\n";
        exit(3);
} else if ($check['status'] == 'paused') {
        print "WARNING : ".$check['name']." (".$check['hostname'].") is WARNING | time=".$check['lastresponsetime']."\n";
        exit(1);
}

?>

