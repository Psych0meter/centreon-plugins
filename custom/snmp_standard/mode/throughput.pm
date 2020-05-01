package custom::snmp_standard::mode::throughput;

use base qw(centreon::plugins::mode);
use IO::Socket;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
									"warning:s"		=> { name => 'warning', default => 80},
									"critical:s"	=> { name => 'critical', default => 90},
									"speed:s"		=> { name => 'speed', default => 10000000000},
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    my $speed = '10000000000';
    $speed = $self->{option_results}->{speed} if ($self->{option_results}->{speed});

    # OID
    $self->{oid_speed32} = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
    $self->{oid_in32} = '.1.3.6.1.2.1.2.2.1.10'; # in B
    $self->{oid_out32} = '.1.3.6.1.2.1.2.2.1.16'; # in B
    $self->{oid_speed64} = '.1.3.6.1.2.1.31.1.1.1.15'; # need multiple by '1000000'
    $self->{oid_in64} = '.1.3.6.1.2.1.31.1.1.1.6'; # in B
    $self->{oid_out64} = '.1.3.6.1.2.1.31.1.1.1.10'; # in B

    my $oid_32 = '.1.3.6.1.2.1.2.2.1';
    my $oid_64 = '.1.3.6.1.2.1.31.1.1.1';


    #my $result64 = $self->{snmp}->get_table( oid => $oid_64 );
    #my $result32 = $self->{snmp}->get_table( oid => $oid_32 );
    my $result_in  = $self->{snmp}->get_table( oid => $self->{oid_in64} );
    my $result_out = $self->{snmp}->get_table( oid => $self->{oid_out64} );
    
    my ($total_in, $total_out) = (0, 0);

    foreach my $key (keys %$result_in) {
	#print $key." --> ".$result_in->{$key}."\n";
	$total_in += $result_in->{$key};
    }

    foreach my $key (keys %$result_out) {
        #print $key." --> ".$result_out->{$key}."\n";
        $total_out += $result_out->{$key};
    }

    #print "Total In : $total_in\n";
    #print "Total In : $total_out\n";

    my $in_bits = $total_in;
    my $out_bits = $total_out;

    # Cache file
    my $last_in_bits = 0;
    my $last_out_bits  = 0;
    my $flg_created = 0;
    my $last_check_time = 0;

    my $file_path = "/var/lib/centreon/centplugins/custom_cache_snmpstandard_".$self->{option_results}->{host}."_throughput";
    if (-e $file_path) {
        open(FILE,"<".$file_path);
        while(my $row = <FILE>){
                my @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_in_bits = $last_values[1];
                $last_out_bits = $last_values[2];
                $flg_created = 1;
        }
        close(FILE);
    } else {
        $flg_created = 0;
    }

    my $update_time = time();

    unless (open(FILE,">".$file_path)){
	$self->{output}->add_option_msg(short_msg => "Check mod for temporary file : ".$file_path." !");
        $self->{output}->option_exit();
    }

    print FILE "$update_time:$in_bits:$out_bits";
    close(FILE);

    if ($flg_created == 0){
	$self->{output}->output_add(        severity => 'OK',
					    short_msg => "First execution : Buffer in creation.... ");
	$self->{output}->display();
	$self->{output}->option_exit();
    }

    # Compare values with previous check
    my ($in_traffic, $out_traffic) = (0, 0);

    if (($in_bits - $last_in_bits != 0) && defined($last_in_bits)) {
        my $total = 0;
        if ($in_bits - $last_in_bits < 0){
                $total = 4294967296 * 8 - $last_in_bits + $in_bits;
        } else {
                $total = $in_bits - $last_in_bits;
        }
        my $diff = time() - $last_check_time;
        if ($diff == 0){$diff = 1;}
        my $pct_in_traffic = $in_traffic = abs($total / $diff);
    } else {
        $in_traffic = 0;
    }

    if ($out_bits - $last_out_bits != 0 && defined($last_out_bits)) {
        my $total = 0;
        if ($out_bits - $last_out_bits < 0){
                $total = 4294967296 * 8 - $last_out_bits + $out_bits;
        } else {
                $total = $out_bits - $last_out_bits;
        }
        my $diff =  time() - $last_check_time;
        if ($diff == 0){$diff = 1;}
        my $pct_out_traffic = $out_traffic = abs($total / $diff);
    } else {
        $out_traffic = 0;
    }

    # Check thresholds
    my $in_percentage = $in_traffic / $speed * 100;
    my $out_percentage = $out_traffic / $speed * 100;

    my $severity = "OK";

    if (($in_percentage >= $self->{option_results}->{critical}) || ($out_percentage >= $self->{option_results}->{critical})) {
	$severity = "CRITICAL";
    } elsif (($in_percentage >= $self->{option_results}->{warning}) || ($out_percentage >= $self->{option_results}->{warning})) {
	$severity = "WARNING";
    }

 
    # Convert units
    my $in_prefix = "";
    my $out_prefix = "";

    my $in_perfparse_traffic = $in_traffic;
    my $out_perfparse_traffic = $out_traffic;
    
    ($in_traffic, $in_prefix) = convert($in_traffic);
    ($out_traffic, $out_prefix) = convert($out_traffic);

    my $in_perfparse_traffic_str = sprintf("%.2f",abs($in_perfparse_traffic));
    my $out_perfparse_traffic_str = sprintf("%.2f",abs($out_perfparse_traffic));

    $in_perfparse_traffic_str =~ s/\./,/g;
    $out_perfparse_traffic_str =~ s/\./,/g;

    # Print output
    $self->{output}->output_add(severity => $severity, short_msg => sprintf ("Traffic In : %.2f%sb/s (%.2f%%), Traffic Out : %.2f%sb/s (%.2f%%)", $in_traffic, $in_prefix, $in_percentage, $out_traffic, $out_prefix, $out_percentage));

    $self->{output}->perfdata_add(label => 'traffic_in', unit => 'Bits/s',
                                  value => $in_perfparse_traffic_str);

    $self->{output}->perfdata_add(label => 'traffic_out', unit => 'Bits/s',
                                  value => $out_perfparse_traffic_str);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

# Conversion function

sub convert {
        my $traffic = shift;
        my $prefix = "";

        if ($traffic / 1073741824 > 1) {
                $traffic = $traffic / 1073741824;
                $prefix = "G";
        } elsif ($traffic / 1048576 > 1) {
                $traffic = $traffic / 1048576;
                $prefix = "M";
        } elsif ($traffic / 1024 > 1) {
                $traffic = $traffic / 1024;
                $prefix = "k";
        }

        return $traffic, $prefix;
}

__END__

