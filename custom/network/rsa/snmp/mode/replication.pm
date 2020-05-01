package custom::network::rsa::snmp::mode::replication;

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
                                  "instance:s" => { name => 'instance' },
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

    my $oid_rsa = '.1.3.6.1.4.1.2197.20.21.1';
    my $oid_rsa_instance = '.1.3.6.1.4.1.2197.20.21.1.2';
    my $oid_rsa_desc = '.1.3.6.1.4.1.2197.20.21.1.4';
    my $oid_rsa_status = '.1.3.6.1.4.1.2197.20.21.1.5';

    my $result = $self->{snmp}->get_table(oid => $oid_rsa);

    my $severity = 'OK';
    my $output;   

    # Check instance
    if (!($self->{option_results}->{instance})) {
	$severity = 'UNKNOWN';
	$output = '--instance parameter not specified.';
    } else {
 	my $instance_exists = 0;
	my $instance_oid;

	foreach my $key (keys %{ $result }) {
	    if ($result->{$key} eq $self->{option_results}->{instance}) {
		$instance_exists++;
		$instance_oid = $key;
		$instance_oid =~ s/$oid_rsa_instance//;
	    }
	}

        if ($instance_exists eq 0) {
	    $severity = 'CRITICAL';
	    $output = 'Instance '.$self->{option_results}->{instance}.' does not exists.';
	} else {
	    my $instance_status = $result->{$oid_rsa_status.$instance_oid};
	    my $instance_desc = $result->{$oid_rsa_desc.$instance_oid};

	    if ($instance_status eq 'HEALTHY') {
		$severity = 'OK';
	    } else {
		$severity = 'CRITICAL'
	    }
	    $output = 'Instance '.$self->{option_results}->{instance}.' ('.$instance_desc.') is '.$instance_status;
	}
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

Check instance replication status

=over 8

=item B<--instance>

Instance name.

=back

=cut
