package custom::hardware::devices::hitachi::hcp::snmp::mode::storage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Switch;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', default => 80 },
                                  "critical:s"              => { name => 'critical', default => 90 },
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_node_number		= '.1.3.6.1.4.1.116.5.46.2.1.1.2';
    my $oid_usage		= '.1.3.6.1.4.1.116.5.46.2.1.1.3';
    my $oid_availability	= '.1.3.6.1.4.1.116.5.46.2.1.1.4';
    my $oid_capacity	        = '.1.3.6.1.4.1.116.5.46.2.1.1.5';
    my $oid_channel_unit        = '.1.3.6.1.4.1.116.5.46.2.1.1.6';
    my $oid_status	        = '.1.3.6.1.4.1.116.5.46.2.1.1.7';


    my $result;
    my $nb_node = 0;

    # Get node number list
    my $result_node_number = $self->{snmp}->get_table(oid => $oid_node_number);
    foreach my $oid (keys %{$result_node_number}) {
	my $id = $oid;
	$id =~ s/.*\.(\d+)$/$1/gi;
	$result->{$id}->{"node_number"} = $result_node_number->{$oid};
	$nb_node++;
    }

    # Get usage list
    my $result_usage = $self->{snmp}->get_table(oid => $oid_usage);
    foreach my $oid (keys %{$result_usage}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"usage"} = $result_usage->{$oid};
        $nb_node++;
    }

    # Get availability list
    my $result_availability = $self->{snmp}->get_table(oid => $oid_availability);
    foreach my $oid (keys %{$result_availability}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"availability"} = $result_availability->{$oid};
        $nb_node++;
    }

    # Get capacity list
    my $result_capacity = $self->{snmp}->get_table(oid => $oid_capacity);
    foreach my $oid (keys %{$result_capacity}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"capacity"} = $result_capacity->{$oid};
        $nb_node++;
    }

    # Get channel unit list
    my $result_channel_unit = $self->{snmp}->get_table(oid => $oid_channel_unit);
    foreach my $oid (keys %{$result_channel_unit}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"channel_unit"} = $result_channel_unit->{$oid};
        $nb_node++;
    }

    # Get status list
    my $result_status = $self->{snmp}->get_table(oid => $oid_status);
    foreach my $oid (keys %{$result_status}) {
        my $id = $oid;
        $id =~ s/.*\.(\d+)$/$1/gi;
        $result->{$id}->{"status"} = $result_status->{$oid};
        $nb_node++;
    }

    my $critical = 0;
    my $warning = 0;
    my $output = "";
    my $output_long = "";

    # Parse results
    foreach my $id (sort keys %{$result}) {
	my $status_display;

	my $node_number 	= $result->{$id}->{"node_number"};
        my $usage 		= $result->{$id}->{"usage"};
        my $availability 	= $result->{$id}->{"availability"};
        my $capacity 		= $result->{$id}->{"capacity"};
        my $channel_unit 	= $result->{$id}->{"channel_unit"};
	my $status 		= $result->{$id}->{"status"};

        my $usage_percent = sprintf("%.2f", $result->{$id}->{"usage"} * 100 / $result->{$id}->{"capacity"});
	my $error = 0;

	switch($status) {
	   case 0	{ 	$status_display = "unavailable"; $critical++; $error++; }
	   case 1       { 	$status_display = "broken"; $critical++; $error++; }
	   case 2   	{ 	$status_display = "suspended"; $critical++; $error++; }
	   case 3    	{ 	$status_display = "initialized"; }
	   case 4       { 	$status_display = "available"; }
	   case 5      	{ 	$status_display = "degraded"; $critical++; $error++; }
	}

	if ($usage_percent >= $self->{option_results}->{critical}) {
		$critical++;
		$error++;
	} elsif ($usage_percent >= $self->{option_results}->{warning}) {
		$warning++;
		$error++;
	}

	if ($error > 0) {
	        $output .= " / " if (($critical > 0) || ($warning > 0));
		$output .= "Storage ID $id (Node $node_number - Channel Unit $channel_unit) is $status_display - Usage : $usage_percent%";
	}

	$output_long .= "Storage ID $id (Node $node_number - Channel Unit $channel_unit) is $status_display - Usage : $usage_percent%\n";

        $self->{output}->perfdata_add(label => "node_".$id, unit => 'B',
                                      value => $result->{$id}->{"usage"},
                                      min => 0, max => $result->{$id}->{"capacity"});

    }

    my $exit = "OK";
    $exit = "WARNING" if ($warning > 0);
    $exit = "CRITICAL" if ($critical > 0);
    
    $output = "All storages are OK" if ($output eq "");

    $self->{output}->output_add(	severity => $exit,
					short_msg => $output,
					long_msg => $output_long);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__
