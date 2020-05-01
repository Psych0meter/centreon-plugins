#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use DateTime;
use Switch;
use lib "/usr/lib64/nagios/plugins";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Scalar::Util qw/looks_like_number/;

my $centreonpath = "/usr/share/centreon/www/modules/";

# Options
my ($opt_h, $opt_m, $opt_w, $opt_c);

# Output string declaration
my $output = '';

Getopt::Long::Configure('bundling');
GetOptions (
        "h"   => \$opt_h,       # Help
        "m=s" => \$opt_m,   # module name
        "w=i" => \$opt_w,       # Warning threshold
        "c=i" => \$opt_c,       # Critical threshold
);

if ($opt_c > $opt_w)
{
        print "UNKNOWN - Critical is greater than Warning";
}
else
{
        my $modulepath=$centreonpath.$opt_m."/license/merethis_lic.zl";

        my $dateofexpire = `cat $modulepath | grep 'Expires = ' | awk -F" = " '{print \$2}'`;

        my @date = split /-/, $dateofexpire;

        my $month="";

        switch ($date[1]) {
                        case "Jan"      { $month=1 }
                        case "Feb"      { $month=2 }
                        case "Mar"      { $month=3 }
                        case "Apr"      { $month=4 }
                        case "May"      { $month=5 }
                        case "Jun"      { $month=6 }
                        case "Jul"      { $month=7 }
                        case "Aug"      { $month=8 }
                        case "Sep"      { $month=9 }
                        case "Oct"      { $month=10 }
                        case "Nov"      { $month=11 }
                        case "Dec"      { $month=12 }
        }

        my $dt1 = DateTime->new(
                year       => $date[2],
                month      => $month,
                day        => $date[0],
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
