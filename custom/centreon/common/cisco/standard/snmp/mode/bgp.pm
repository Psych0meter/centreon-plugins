package custom::centreon::common::cisco::standard::snmp::mode::bgp;

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
									"critical:s"              => { name => 'critical' }
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_ciscoBGP = '.1.3.6.1.2.1.15.3.1.1';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ciscoBGP }
								],
                                                   nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK');
    
    if (!$self->{results}) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Cannot find BGP informations."));
    }

    # Get BGP session list
    my %peerArray = %{$self->{results}->{$oid_ciscoBGP}};
    
    my @peerNames;
    my $peerNumber = 0;

    foreach (keys %peerArray) {
        $peerNumber++;
        push(@peerNames, $self->{results}->{$oid_ciscoBGP}->{$_});
    }

    if ( $peerNumber <= $self->{option_results}->{critical}) {
        $self->{output}->output_add(severity => 'CRITICAL', 
				short_msg => sprintf("BGP Session number is less or equal to %s.", $self->{option_results}->{critical}));
    }

    my $peerList = join(', ', sort(@peerNames));

    $self->{output}->output_add(short_msg => sprintf("BGP Sessions : %s (%s)", $peerNumber, $peerList));

    $self->{output}->perfdata_add(label => "session", value => $peerNumber);


    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check CISCO BGP Sessions

=over 8

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
