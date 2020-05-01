package custom::os::windows::snmp::mode::service;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_installed_state = (
    1 => 'uninstalled',
    2 => 'install-pending',
    3 => 'uninstall-pending',
    4 => 'installed'
);
my %map_operating_state = (
    1 => 'active',
    2 => 'continue-pending',
    3 => 'pause-pending',
    4 => 'paused'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                  "service:s"          => { name => 'service', },
                                  "regexp"             => { name => 'use_regexp', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{service})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify at least one '--service' option.");
       $self->{output}->option_exit();
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_svSvcName  = '.1.3.6.1.4.1.77.1.2.3.1.1';
    my $result = $self->{snmp}->get_table(oid => $oid_svSvcName);
    my $severity = 'OK';
    my $output = "(Service list : ".$self->{option_results}->{service}.")";

    @{$self->{option_results}->{service_list}} = split(/,/, $self->{option_results}->{service});


    my $nb_services = @{$self->{option_results}->{service_list}};
    my $nb_services_running = 0;
    my $services_status;

    foreach my $svc_name (@{$self->{option_results}->{service_list}}) {
        $services_status->{$svc_name} = 0;
        foreach my $key ( keys %{$result} ) {
		if ($result->{$key} eq $svc_name) {
	        	$services_status->{$svc_name} = 1;
	                $nb_services_running++;
        	        last;
		}
	}
    }

    my $output_error = '';
    my @services_error;

    if ($nb_services_running ne $nb_services) {
        $severity = 'CRITICAL';
        foreach my $svc (keys %$services_status) {
                push(@services_error,$svc) if ($services_status->{$svc} eq '0');
        }

        local $" = ',';
        $output_error = "-> @services_error not running ";
    }

    $output = "Service(s) running : $nb_services_running/$nb_services ".$output_error.$output;

    $self->{output}->output_add(severity => $severity,
                                short_msg => $output,);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Windows Services with SNMP

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--service>

Services to check. (can set multiple times)

=item B<--regexp>

Allows to use regexp to filter services.

=item B<--state>

Service state. (Regexp allowed)

=back

=cut
