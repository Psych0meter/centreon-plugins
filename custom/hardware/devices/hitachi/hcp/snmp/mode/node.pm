package custom::hardware::devices::hitachi::hcp::snmp::mode::node;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_ip			= '.1.3.6.1.4.1.116.5.46.1.1.1.2';
    my $oid_status		= '.1.3.6.1.4.1.116.5.46.1.1.1.7';
    my $oid_nic_degraded	= '.1.3.6.1.4.1.116.5.46.1.1.1.14';

    my $result;
    my $nb_node = 0;

    # Get IP list
    my $result_ip = $self->{snmp}->get_table(oid => $oid_ip);
    foreach my $oid (keys %{$result_ip}) {
	my $id = $oid;
	$id =~ s/.*\.(\d+)$/$1/gi;
	$result->{$id}->{"ip"} = $result_ip->{$oid};
	$nb_node++;
    }

    # Get status list
    my $result_status = $self->{snmp}->get_table(oid => $oid_status);
#                   unavailable(0),
#                   available(4)
    foreach my $oid (keys %{$result_status}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"status"} = $result_status->{$oid};
    }

    # Get NIC degraded list
    my $result_nic_degraded = $self->{snmp}->get_table(oid => $oid_nic_degraded);
#                   yes(1),
#                   no(2)
    foreach my $oid (keys %{$result_nic_degraded}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"nic_degraded"} = $result_nic_degraded->{$oid};

    }

    my $critical = 0;
    my $output = "";
    my $output_long = "";
    my $index = 0;

    # Parse results
    foreach my $id (sort keys %{$result}) {
	my $status_display;
	my $nic_degraded_display;

	my $ip = $result->{$id}->{"ip"};
	my $status = $result->{$id}->{"status"};
	my $nic_degraded = $result->{$id}->{"nic_degraded"};

	my $error = 0;

	if ($status eq 0) {
		$status_display = "unavailable";
		$critical++;
		$error++;
	} else {
		$status_display = "available";
	}
	
        if ($nic_degraded eq 1) {
                $nic_degraded_display = "degraded";
                $critical++;
		$error++;
        } else {
                $nic_degraded_display = "ok";
        }

	if ($error > 0) {
		$output .= " / " if ($critical > 0);
		$output .= "$ip is $status_display (NIC is $nic_degraded_display)";
	}
	
	$output_long .= "$ip is $status_display (NIC is $nic_degraded_display)\n";
	$index++;
    }

    my $exit = "OK";
    $exit = "CRITICAL" if ($critical > 0);
    $output = "All nodes are OK" if ($output eq "");

    $self->{output}->output_add(        severity => $exit,
                                        short_msg => $output,
                                        long_msg => $output_long);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__
