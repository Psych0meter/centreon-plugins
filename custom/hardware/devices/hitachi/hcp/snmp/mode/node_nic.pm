package custom::hardware::devices::hitachi::hcp::snmp::mode::node_nic;

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
    my $oid_nic_failure         = '.1.3.6.1.4.1.116.5.46.1.1.1.11';
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

    # Get NIC failure list
    my $result_nic_failure = $self->{snmp}->get_table(oid => $oid_nic_failure);
#                   yes(1),
#                   no(2)
    foreach my $oid (keys %{$result_nic_failure}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"nic_failure"} = $result_nic_failure->{$oid};
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
	my $nic_failure_display;
        my $nic_degraded_display;

	my $ip = $result->{$id}->{"ip"};
        my $nic_failure = $result->{$id}->{"nic_failure"};
	my $nic_degraded = $result->{$id}->{"nic_degraded"};

	my $error = 0;

        if ($nic_failure eq 1) {
                $nic_failure_display = "failed";
                $output .= " / " if ($critical > 0);
                $output .= "$ip NIC is $nic_failure_display";
                $critical++;
                $error++;
        } else {
                $nic_failure_display = "ok";
        }

        if ($nic_degraded eq 1) {
                $nic_degraded_display = "degraded";
                $output .= " / " if ($critical > 0);
                $output .= "$ip NIC is $nic_degraded_display";
                $critical++;
		$error++;
        } else {
                $nic_degraded_display = "ok";
        }
	
	$output_long .= "$ip NIC failure status is $nic_failure_display\n";
        $output_long .= "$ip NIC degraded status is $nic_degraded_display\n";
	$index++;
    }

    my $exit = "OK";
    $exit = "CRITICAL" if ($critical > 0);
    $output = "All nodes NIC are OK" if ($output eq "");

    $self->{output}->output_add(        severity => $exit,
                                        short_msg => $output,
                                        long_msg => $output_long);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__
