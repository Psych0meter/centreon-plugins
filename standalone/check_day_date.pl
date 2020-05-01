#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use DateTime;
use lib "/usr/lib64/nagios/plugins";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Scalar::Util qw/looks_like_number/;

# Options
my ($opt_h,$opt_d, $opt_w, $opt_c);

# Output string declaration
my $output = '';

Getopt::Long::Configure('bundling');
GetOptions (
        "h"   => \$opt_h,       # Help
        "d=s" => \$opt_d,       # licences end date exemple 2019-04-12
        "w=i" => \$opt_w,       # Warning threshold
        "c=i" => \$opt_c,       # Critical threshold
);

if ($opt_c > $opt_w) {
        print "UNKNOWN - Critical must be lower than Warning";
} else {

        my $dateofexpire = $opt_d;

        my @date = split /-/, $opt_d;

        my $dt1 = DateTime->new(
                year       => $date[0],
                month      => $date[1],
                day        => $date[2],
                hour       => 0,
                minute     => 0,
                second     => 0,
                nanosecond => 0,
                time_zone  => "floating",
        );

        my $dt2 = DateTime->today();

        # Days between 2 dates
        my $days = $dt1->delta_days($dt2)->delta_days;

        # dt1 < dt2 --> -1
        my $cmp = DateTime->compare($dt1, $dt2);

        if ($cmp <= 0) {
                print "CRITICAL - License is expired.";
                exit 2;
        } else {
                if ($days <= $opt_c) {
                        print "CRITICAL - License expire in $days day(s).";
                        exit 2;
                } elsif ($days <= $opt_w) {
                        print "WARNING - License expire in $days day(s).";
                        exit 1;
                } else {
                        print "OK - License expire in $days day(s).";
                        exit 0;
                }
        }
}
