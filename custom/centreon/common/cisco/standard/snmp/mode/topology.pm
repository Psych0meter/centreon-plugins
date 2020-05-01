package custom::centreon::common::cisco::standard::snmp::mode::topology;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Net::SNMP qw(:snmp oid_lex_sort);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
									"vlan:s" => { name => 'vlan' }
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ($self->{option_results}->{snmp_version} ne "2c" ) {
       $self->{output}->add_option_msg(short_msg => "This plugin only supports SNMP v2c");
       $self->{output}->option_exit();
    }
}


sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my ($session,$error) = Net::SNMP->session(
        -timeout => 2,
        -retries => 1,
        -hostname => $self->{option_results}->{host},
        -community => $self->{option_results}->{snmp_community}."@".$self->{option_results}->{vlan},
        -version => $self->{option_results}->{snmp_version},
    );

    if (!defined($session)) {
	$self->{output}->add_option_msg(short_msg => "Error fetching informations from ".$self->{option_results}->{host}.": $error");
        $self->{output}->option_exit();
    }

    my $oid_topology = '1.3.6.1.2.1.17.2';

    my $result = $session->get_table(-baseoid => $oid_topology);

    my $value = 0;
    my $time = '';

    foreach my $key (keys %$result) {
        $value = $result->{'1.3.6.1.2.1.17.2.4.0'};
	$time = $result->{'1.3.6.1.2.1.17.2.3.0'};
    }

    if ($time eq '') {
        $self->{output}->add_option_msg(short_msg => "Error getting topology change time value");
        $self->{output}->option_exit();
    }


    $self->{output}->output_add(short_msg => sprintf("Number of topology changes : %s<br />Time since last change : %s", $value, $time));

    $self->{output}->perfdata_add(label => "changes", value => $value);

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check CISCO topology changes

=over 8

=item B<--vlan>

VLAN name

=back

=cut
    
