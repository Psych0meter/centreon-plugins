#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use HTTP::Request;
use LWP::UserAgent;
use Switch;
use XML::LibXML;

# Do not check SSL certificate
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my ($hostname, $token, $mode);
my $warning = 80;
my $critical = 90;

GetOptions (	"hostname=s"	=> \$hostname,
		"token=s"	=> \$token,
		"mode=s"	=> \$mode,
		"warning=i"	=> \$warning,
		"critical=i"	=> \$critical,
) or die("Error in command line arguments\n");

if (!(defined $hostname) || !(defined $token) || !(defined $mode)) {
        print "UNKNOWN - Options not set properly.";
	exit 3;
}

switch($mode) {
	case "uptime"	{ nsx_uptime(); }
	case "dns"	{ nsx_dns(); }
	case "cpu"	{ nsx_cpu(); }
	case "memory"	{ nsx_memory(); }
	case "storage"	{ nsx_storage(); }
        case "controller"	{ nsx_controller(); }
	case "ntp"	{ nsx_ntp(); }
        case "backup"	{ nsx_backup(); }
	case "component"	{ nsx_component(); }
	else		{ print "UNKNOWN - Unknown mode"; exit 3; }
}

sub nsx_uptime {
	my $url = "https://$hostname/api/1.0/appliance-management/system/uptime";
	my $header = [
	        'Accept'        => "application/xml",
	        'Authorization' => "Basic $token",
	];
	my $ua  = LWP::UserAgent->new;
	my $request = HTTP::Request->new('GET', $url, $header);
	my $content = $ua->request($request) or die "Cannot connect to $url: $_";
	my $result = $content->{'_content'} or die "No content in web page_ $_";

	print "Uptime : $result\n";
	exit 0;
}	

sub nsx_dns {
        my $url = "https://$hostname/api/1.0/appliance-management/summary/system";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

        my $dom = XML::LibXML->load_xml(string => $result);

	my $dns = $dom->findvalue('/systemSummary/dnsName');

	print "DNS : $dns\n";
	exit 0;
}	

sub nsx_cpu {
        my $url = "https://$hostname/api/1.0/appliance-management/system/cpuinfo";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

	my $dom = XML::LibXML->load_xml(string => $result);

	my $cpu_nb 		= $dom->findvalue('/cpuInfo/totalNoOfCPUs');
	my $cpu_capacity_total 	= $dom->findvalue('/cpuInfo/capacity');
	my $cpu_capacity_used 	= $dom->findvalue('/cpuInfo/usedCapacity');
	my $cpu_capacity_free 	= $dom->findvalue('/cpuInfo/freeCapacity');
	my $cpu_percentage_used = $dom->findvalue('/cpuInfo/usedPercentage');
	my $cpu_indicator 	= $dom->findvalue('/cpuInfo/cpuUsageIndicator');

	print "CPU usage is $cpu_indicator / $cpu_percentage_used% (Total: $cpu_capacity_total, Used: $cpu_capacity_used, Free: $cpu_capacity_free / $cpu_nb CPU(s))|'used'=$cpu_percentage_used%;$warning;$critical";

	if ($cpu_percentage_used >= $critical) {
		exit 2;
	} elsif ($cpu_percentage_used >= $warning) {
		exit 1;
	} else {
		exit 0;
	}
}	

sub nsx_memory {
        my $url = "https://$hostname/api/1.0/appliance-management/system/meminfo";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

        my $dom = XML::LibXML->load_xml(string => $result);

        my $memory_total	= $dom->findvalue('/memInfo/totalMemory');
        my $memory_used		= $dom->findvalue('/memInfo/usedMemory');
        my $memory_free		= $dom->findvalue('/memInfo/freeMemory');
        my $memory_percentage_used	= $dom->findvalue('/memInfo/usedPercentage');

        print "Memory usage is $memory_percentage_used% (Total: $memory_total, Used: $memory_used, Free: $memory_free)|'used'=$memory_percentage_used%;$warning;$critical";

        if ($memory_percentage_used >= $critical) {
                exit 2;
        } elsif ($memory_percentage_used >= $warning) {
                exit 1;
        } else {
                exit 0;
        }
}

sub nsx_storage {
        my $url = "https://$hostname/api/1.0/appliance-management/system/storageinfo";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

        my $dom = XML::LibXML->load_xml(string => $result);

        my $storage_total	= $dom->findvalue('/storageInfo/totalStorage');
        my $storage_used	= $dom->findvalue('/storageInfo/usedStorage');
        my $storage_free	= $dom->findvalue('/storageInfo/freeStorage');
        my $storage_percentage_used	= $dom->findvalue('/storageInfo/usedPercentage');

        print "Storage usage is $storage_percentage_used% (Total: $storage_total, Used: $storage_used, Free: $storage_free)|'used'=$storage_percentage_used%;$warning;$critical";
        if ($storage_percentage_used >= $critical) {
                exit 2;
        } elsif ($storage_percentage_used >= $warning) {
                exit 1;
        } else {
                exit 0;
        }
}

sub nsx_controller {
        my $url = "https://$hostname/api/2.0/vdn/controller";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

	my $dom = XML::LibXML->load_xml(string => $result);

        my $index = 0;
        my $error = 0;
        my $return_string = "";

        foreach my $controller ($dom->findnodes('/controllers/controller')) {
		my $name 	= $controller->findvalue('./name');
		my $id	 	= $controller->findvalue('./id');
		my $status 	= $controller->findvalue('./status');

                $return_string .= " / " if ($index > 0);
                $return_string .= "$name ($id) is $status";
                $error++ if ($status ne "RUNNING");

                $index++;
        }

        print $return_string;

        exit 2 if ($error > 0);
        exit 0;
}

sub nsx_ntp {
        my $url = "https://$hostname/api/1.0/appliance-management/system/timesettings";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

        my $dom = XML::LibXML->load_xml(string => $result);
        my $ntp_datetime = $dom->findvalue('/timeSettings/datetime');

	print "Datetime : $ntp_datetime";

	exit 0;
}

sub nsx_backup {
        my $url = "https://$hostname/api/1.0/appliance-management/backuprestore/backups";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

        my $dom = XML::LibXML->load_xml(string => $result);

        my $ok = 0;
	my $now = time() * 1000;

        foreach my $backup ($dom->findnodes('/list/backupFileProperties')) {
		my $filename 		= $backup->findvalue('./fileName');
		my $creationTime 	= $backup->findvalue('./creationTime');
		$ok++ if (($now - $creationTime) < 3600000);
        }

	if ($ok > 0) {
        	print "Last backup younger than 1 hour";
		exit 0;
	} else {
		print "Last backup older than 1 hour";
		exit 2;
	}
}

sub nsx_component {
        my $url = "https://$hostname/api/1.0/appliance-management/summary/components";
        my $header = [
                'Accept'        => "application/xml",
                'Authorization' => "Basic $token",
        ];
        my $ua  = LWP::UserAgent->new;
        my $request = HTTP::Request->new('GET', $url, $header);
        my $content = $ua->request($request) or die "Cannot connect to $url: $_";
        my $result = $content->{'_content'} or die "No content in web page_ $_";

	my $dom = XML::LibXML->load_xml(string => $result);

	my $index = 0;
	my $error = 0;
	my $return_string = "";

	foreach my $component ($dom->findnodes('/componentsSummary/componentsByGroup/entry/components/component')) {
		my $group 	= $component->findvalue('../../string');
		my $componentid = $component->findvalue('./componentId');
                my $name 	= $component->findvalue('./name');
                my $status 	= $component->findvalue('./status');
                my $enabled 	= $component->findvalue('./enabled');

		next if ($componentid eq "NSXREPLICATOR");

		if ($enabled eq "true") {
			$return_string .= " / " if ($index > 0);
			$return_string .= "$name is $status";
			$error++ if ($status ne "RUNNING");
		}

		$index++;
	}

	print $return_string;
	exit 2 if ($error > 0);
	exit 0;
}


1;

