package custom::network::stonesoft::snmp::mode::clusterstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oper_state = (
    0 => ['unknown', 'UNKNOWN'],
    1 => ['online', 'OK'], 
    2 => ['goingOnline', 'WARNING'], 
    3 => ['lockedOnline', 'WARNING'],
    4 => ['goingLockedOnline', 'WARNING'],
    5 => ['offline', 'CRITICAL'],
    6 => ['goingOffline', 'CRITICAL'],
    7 => ['lockedOffline', 'CRITICAL'],
    8 => ['goingLockedOffline', 'CRITICAL'],
    9 => ['standby', 'CRITICAL'],
    10 => ['goingStandby', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
					 "standbyisok"   => { name => 'standby_isok' },
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

    my $oid_nodeMemberId = '.1.3.6.1.4.1.1369.6.1.1.2.0';
    my $oid_nodeOperState = '.1.3.6.1.4.1.1369.6.1.1.3.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_nodeMemberId, $oid_nodeOperState], nothing_quit => 1);
    
    my $status = ${$oper_state{$result->{$oid_nodeOperState}}}[1];
    if (defined($self->{option_results}->{standby_isok}) && ${$oper_state{$result->{$oid_nodeOperState}}}[0] =~ m/standby/) {
		$status = "OK";
    }

    $self->{output}->output_add(severity => $status,
                                short_msg => sprintf("Node status is '%s' [Member id : %s]", 
                                            ${$oper_state{$result->{$oid_nodeOperState}}}[0],
                                            $result->{$oid_nodeMemberId}));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check status of clustered node.

=over 8

=back

=cut
    

