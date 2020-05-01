package custom::os::linux::snmp::mode::snmpexec;

use base qw(centreon::plugins::mode);
use Switch;

use strict;
use warnings;

#.1.3.6.1.4.1.2021.8.1.2.1 = STRING: check-cpu-stats

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "command:s"	=> { name => 'command' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{command})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a command.");
       $self->{output}->option_exit(); 
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oidCommand = ".1.3.6.1.4.1.2021.8.1.2";

    my $idCommand = '';
    my $severity = 'OK';
    my $output = '';
    my $output_result = '';

    my $result = $self->{snmp}->get_table(oid => $oidCommand);

    foreach my $oid (keys %{$result}) {
	if ($result->{$oid} eq $self->{option_results}->{command}) {
		$idCommand = $oid;
		$idCommand =~ s/$oidCommand//gi;
		last;
	}
    } 

    if ($idCommand eq '') {
	$severity = 'UNKNOWN';
	$output = 'Command name "'.$self->{option_results}->{command}.'" does not exist';
    } else {
	my $oidCommandOutput = ".1.3.6.1.4.1.2021.8.1.101".$idCommand;
	my $result_command = $self->{snmp}->get_leef(oids => [$oidCommandOutput]);
	$output = $result_command->{$oidCommandOutput};

	my $oidCommandResult = ".1.3.6.1.4.1.2021.8.1.100".$idCommand;
	my $result_output = $self->{snmp}->get_leef(oids => [$oidCommandResult]);
	$output_result = $result_output->{$oidCommandResult};
    }

    switch ($output_result) {
		case (0)	{ $severity = 'OK' }
        case (1)	{ $severity = 'WARNING' }
        case (2)	{ $severity = 'CRITICAL' }
        case (3)	{ $severity = 'UNKNOWN' }
		else		{ $severity = 'UNKNOWN' }
    }
 
    $self->{output}->output_add(severity => $severity,
                                short_msg => $output);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Execute command through SNMP.

=item B<--command>

Command declared in SNMP configuration

=back

=cut
