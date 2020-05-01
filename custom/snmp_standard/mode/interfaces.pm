package custom::snmp_standard::mode::interfaces;

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
									"interface:s"        => { name => 'interface', },
									"warning:s"          => { name => 'warning', default => 80},
									"critical:s"         => { name => 'critical', default => 90},
									"speed:s"	       => { name => 'speed'},
									"add-errors"	       => { name => 'errors'},
									"oid-extra-display:s" => { name => 'oid_extra_display' },
			
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

#    if (!defined($self->{option_results}->{interface}) || ($self->{option_results}->{interface} !~ m/\d+\.\d+\.\d+\.\d+/)) {
    if (!defined($self->{option_results}->{interface}) || ($self->{option_results}->{interface} eq "")) {
	$self->{option_results}->{interface} = inet_ntoa((gethostbyname($self->{option_results}->{host}))[4]);
    }

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

    $self->{oid_speed32} = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
    $self->{oid_in32} = '.1.3.6.1.2.1.2.2.1.10'; # in B
    $self->{oid_out32} = '.1.3.6.1.2.1.2.2.1.16'; # in B
    $self->{oid_speed64} = '.1.3.6.1.2.1.31.1.1.1.15'; # need multiple by '1000000'
    $self->{oid_in64} = '.1.3.6.1.2.1.31.1.1.1.6'; # in B
    $self->{oid_out64} = '.1.3.6.1.2.1.31.1.1.1.10'; # in B

    # Errors
    $self->{oid_ifInDiscards} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oid_ifInErrors} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oid_ifOutDiscards} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oid_ifOutErrors} = '.1.3.6.1.2.1.2.2.1.20';

    # Extra display
    $self->{oid_ifdesc} = '.1.3.6.1.2.1.2.2.1.2';
    $self->{oid_ifalias} = '.1.3.6.1.2.1.31.1.1.1.18';
    $self->{oid_ifname} = '.1.3.6.1.2.1.31.1.1.1.1';

    # OIDs
    my $oid_ipAdEntIfIndex = '.1.3.6.1.2.1.4.20.1.2'; #Interfaces IPs
    my $oid_32 = '.1.3.6.1.2.1.2.2.1';
    my $oid_64 = '.1.3.6.1.2.1.31.1.1.1';

    # Get interface ID
    my $interfaceId;

    if ($self->{option_results}->{interface} =~ m/\d+\.\d+\.\d+\.\d+/) {
	my $result = $self->{snmp}->get_table(oid => $oid_ipAdEntIfIndex);
	$interfaceId = $result->{$oid_ipAdEntIfIndex.".".$self->{option_results}->{interface}};
    } else {
	my $result = $self->{snmp}->get_table(oid => $self->{oid_ifdesc});
	$self->{option_results}->{interface} =~ s/(.*)\$/$1/gi;

	my $interface_oid;

	foreach my $key ( keys %$result ) {
		$interface_oid = $key if $result->{$key} eq $self->{option_results}->{interface};
	}

	$interfaceId = $interface_oid;
	$interfaceId =~ s/.1.3.6.1.2.1.2.2.1.2.(\d+)/$1/gi;
    }

    if (!($interfaceId)) {
        $self->{output}->add_option_msg(short_msg => "Error getting interface for ".$self->{option_results}->{interface}.".");
        $self->{output}->option_exit();
    }

    my $result64 = $self->{snmp}->get_table( oid => $oid_64 );
    my $result32 = $self->{snmp}->get_table( oid => $oid_32 );

    my $interface_result;
    my ($in_bits, $out_bits, $speed);

    # Check if 32 or 64 bits
    my $test64bits = 0;       

    if (%$result64) {
	if ($interface_result->{$self->{oid_in64}.".".$interfaceId}) {
	     $test64bits = 1;
	}
    }

    if ($test64bits eq 1) {
	    $interface_result = $result64;
	    $speed = $interface_result->{$self->{oid_speed64}.".".$interfaceId} * 1000000;
            $in_bits = $interface_result->{$self->{oid_in64}.".".$interfaceId};
            $out_bits = $interface_result->{$self->{oid_out64}.".".$interfaceId};
    } elsif ($test64bits eq 0) {
            $interface_result = $result32;
            $speed = $interface_result->{$self->{oid_speed32}.".".$interfaceId};
            $in_bits = $interface_result->{$self->{oid_in32}.".".$interfaceId};
            $out_bits = $interface_result->{$self->{oid_out32}.".".$interfaceId};

    } else {
            $self->{output}->add_option_msg(short_msg => "Error getting interface details (32 or 64 bits).");
            $self->{output}->option_exit();
    }

    $speed = $self->{option_results}->{speed} if (($self->{option_results}->{speed}) && ($self->{option_results}->{speed} ne ''));


    # Errors
    my ($indiscard, $inerror, $outdiscard, $outerror);
    my $error_output = "";
    if ($self->{option_results}->{errors}) {
	$indiscard  = $interface_result->{$self->{oid_ifInDiscards}.".".$interfaceId};
	$inerror    = $interface_result->{$self->{oid_ifInErrors}.".".$interfaceId};
	$outdiscard = $interface_result->{$self->{oid_ifOutDiscards}.".".$interfaceId};
    	$outerror   = $interface_result->{$self->{oid_ifOutErrors}.".".$interfaceId};

	$error_output = sprintf (", Packets In Discard : %s, Packets In Error : %s, Packets Out Discard : %s, Packets Out Error : %s", $indiscard, $inerror, $outdiscard, $outerror);
    }

    # Extra display
    my $interface;

    if ($self->{option_results}->{oid_extra_display}) {
	$interface_result = $result32;
	$interface = "Interface ".$interface_result->{$self->{oid_ifdesc}.".".$interfaceId};

	if (lc($self->{option_results}->{oid_extra_display}) eq 'ifdesc') {
		$interface_result = $result32;
		$interface .= " [ ".$interface_result->{$self->{oid_ifdesc}.".".$interfaceId}." ] ";
	} elsif (lc($self->{option_results}->{oid_extra_display}) eq 'ifalias') {
		$interface_result = $result64;
                $interface .= " [ ".$interface_result->{$self->{oid_ifalias}.".".$interfaceId}." ] ";
	} elsif (lc($self->{option_results}->{oid_extra_display}) eq 'ifname') {
		$interface_result = $result64;
                $interface .= " [ ".$interface_result->{$self->{oid_ifname}.".".$interfaceId}." ] ";
	}
    }

    # Cache file
    my $last_in_bits = 0;
    my $last_out_bits  = 0;
    my $flg_created = 0;
    my $last_check_time = 0;
    my $last_indiscard = 0;
    my $last_inerror = 0,
    my $last_outdiscard = 0;
    my $last_outerror = 0;

    my $file_path = "/var/lib/centreon/centplugins/custom_cache_snmpstandard_".$self->{option_results}->{host}."_interface_".$interfaceId;
    if (-e $file_path) {
        open(FILE,"<".$file_path);
        while(my $row = <FILE>){
                my @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_in_bits = $last_values[1];
                $last_out_bits = $last_values[2];
		$last_indiscard = $last_values[3];
		$last_inerror = $last_values[4];
		$last_outdiscard = $last_values[5];
		$last_outerror = $last_values[6];
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

    print FILE "$update_time:$in_bits:$out_bits:$indiscard:$inerror:$outdiscard:$outerror";
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

    $speed = 10000000000 if ($speed eq 0);

    # Check thresholds
    my $in_percentage = $in_traffic / $speed * 100;
    my $out_percentage = $out_traffic / $speed * 100;

    my $severity = "OK";

    if (($in_percentage >= $self->{option_results}->{critical}) || ($out_percentage >= $self->{option_results}->{critical})) {
	$severity = "CRITICAL";
    } elsif (($in_percentage >= $self->{option_results}->{warning}) || ($out_percentage >= $self->{option_results}->{warning})) {
	$severity = "WARNING";
    }

    if ($self->{option_results}->{errors}) {
    	if ((abs($indiscard - $last_indiscard) > 0) || (abs($inerror - $last_inerror) > 0) || (abs($outdiscard - $last_outdiscard) > 0) || (abs($outerror - $last_outerror) > 0)) {
            $severity = "CRITICAL";
	}
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
    $self->{output}->output_add(severity => $severity, short_msg => sprintf ("%sTraffic In : %.2f%sb/s (%.2f%%), Traffic Out : %.2f%sb/s (%.2f%%)%s", $interface, $in_traffic, $in_prefix, $in_percentage, $out_traffic, $out_prefix, $out_percentage, $error_output));

    $self->{output}->perfdata_add(label => 'traffic_in', unit => 'Bits/s',
                                  value => $in_perfparse_traffic_str);

    $self->{output}->perfdata_add(label => 'traffic_out', unit => 'Bits/s',
                                  value => $out_perfparse_traffic_str);

    if ($self->{option_results}->{errors}) {
	$self->{output}->perfdata_add(label => 'packets_discard_in', unit => '',
        		              value => $indiscard);
        $self->{output}->perfdata_add(label => 'packets_discard_out', unit => '',
                                      value => $outdiscard);
        $self->{output}->perfdata_add(label => 'packets_error_in', unit => '',
                                      value => $inerror);
        $self->{output}->perfdata_add(label => 'packets_error_out', unit => '',
                                      value => $outerror);
    }

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

