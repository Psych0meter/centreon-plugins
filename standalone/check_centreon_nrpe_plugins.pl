#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Time::Local;

GetOptions (    "host|h=s"      => \(my $host),
                "port|p=i"      => \(my $port = 5666),
                "warning|w=i"   => \(my $warning = 183),
                "critical|c=i"  => \(my $critical = 366),
                "timeout|t=i"   => \(my $timeout = 5),
                "libpath|l=s"   => \(my $libpath = "/usr/lib64/nagios/plugins/check_centreon_nrpe"),
                "help|?"                => sub { help() },
)
or die("Error in command line arguments\n");

if ($warning > $critical) {
        print "UNKNOWN Warning threshold must be lower than Critical threshold.\n";
        help();
        exit(3);
}

if (!($host)) {
        print "UNKNOWN - You have to specify a host.\n";
        help();
        exit(3);
}

my $result = `$libpath -H $host -p $port -t $timeout -u -m 8192 -c check_centreon_plugins -a ' --version'`;

if ( $result =~ m/Global Version: (\d{4})(\d{2})(\d{2})(.*)/ ) {
        my ($year, $month, $day) = ($1, $2, $3);
	my $version = "$1$2$3$4";

        # Get current date
        my @today = localtime();
        my $time = timelocal(@today);

        # Convert date version
        my @versiondate = (0, 0, 0, $day, $month-1, $year);
        my $versiontime = timelocal(@versiondate);

        # Convert time between 2 dates in days
        my $delta = int(($time - $versiontime)/ 86400);

        # Check thresholds
        if ($delta >= $critical) {
                print "CRITICAL - Centreon plugins are older than $critical days (version $version)\n";
                exit(2);
        } elsif ($delta >= $warning) {
                print "WARNING - Centreon plugins are older than $warning days (version $version)\n";
                exit(1);
        } else {
                print "OK - Centreon plugins installed (version $version)\n";
                exit(0);
        }

        print "$delta days";

} else {
        print "UNKNOWN - Cannot get Centreon plugins version\n";
        exit(3);
}

sub help {
        print "Usage: $0 --host HOST [--port PORT] [--warning WARNING] [--critical CRITICAL] [--timeout TIMEOUT] [--libpath LIBPATH]\n";
        print "  -h --host              Hostname or IP Address\n";
        print "  -p --port              NRPE port number (default: 5666)\n";
        print "  -w --warning           Warning threshold in days (default: 183)\n";
        print "  -c --critical          Critical threshold in days (default: 366)\n";
        print "  -t --timeout           NRPE timeout in seconds (default: 5)\n";
        print "  -l --libpath           Path to NRPE check command (default: /usr/lib64/nagios/plugins/check_centreon_nrpe)\n";
        print "  -? --help              Display help\n";
        exit(3);
}

1;
