package custom::network::fortinet::fortigate::snmp::mode::vdomsessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
                                {
                                  "vdom-name:s"             => { name => 'vdom-name', default => '' },
                                  "warning:s"               => { name => 'warning', default => 2500 },
                                  "critical:s"              => { name => 'critical', default => 5000 },

                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    # OIDs
    my $oid_vdom_name     = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';
    my $oid_vdom_sessions = '.1.3.6.1.4.1.12356.101.11.2.2.1.1';

    # Get requests
    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vdom_name },
                                                            { oid => $oid_vdom_sessions },
                                                         ],
                                                         , nothing_quit => 1);

    my $nb_sessions = 0;
    my $vdom_id = '';

    my $severity = 'OK';
    my $output;

    if (($self->{option_results}->{'vdom-name'}) eq '') {
	$severity = 'UNKNOWN';
	$output = 'Please specify a VDOM name.';
    } else {
	foreach my $key ( keys %{$self->{results}->{$oid_vdom_name}} ) {
	   if ($self->{results}->{$oid_vdom_name}->{$key} eq $self->{option_results}->{'vdom-name'}) {
		$vdom_id = $key;
		$vdom_id =~ s/$oid_vdom_name//gi;
		last;
	   }
	}
    }

    if ($vdom_id eq '') { 
	$severity = 'UNKNOWN';
	$output = 'Error getting VDOM ID.';
    } else {
	$nb_sessions = $self->{results}->{$oid_vdom_sessions}->{$oid_vdom_sessions.$vdom_id};
	$output = "Number of VDOM sessions for ".$self->{option_results}->{'vdom-name'}.": ".$nb_sessions;

    	$self->{output}->perfdata_add(label => 'sessions',
                                      value => $nb_sessions);
    }

    if ($nb_sessions >= $self->{option_results}->{'critical'}) {
	$severity = 'CRITICAL';
    } elsif ($nb_sessions >= $self->{option_results}->{'warning'}) {
	$severity = 'WARNING';
    }


    # Print output
    $self->{output}->output_add(severity => $severity, 
				short_msg => $output);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VDOM sessions

=over 8

=item B<--vdom-name>

VDOM name

=item B<--critical>

Critical threshold.

=item B<--warning>

Warning threshold.

=back

=cut

