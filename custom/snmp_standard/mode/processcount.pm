package custom::snmp_standard::mode::processcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my %map_process_status = (
    1 => 'running', 
    2 => 'runnable', 
    3 => 'notRunnable', 
    4 => 'invalid',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', default => 1},
                                  "process-name:s"          => { name => 'process_name', },
                                  "regexp-name"             => { name => 'regexp_name', },
                                  "process-path:s"          => { name => 'process_path', }, # Not operational now
                                  "regexp-path"             => { name => 'regexp_path', }, # Not operational now
                                  "process-args:s"          => { name => 'process_args', }, # Not operational now
                                  "regexp-args"             => { name => 'regexp_args', }, # Not operational now
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

my $oids = {
    name => '.1.3.6.1.2.1.25.4.2.1.2', # hrSWRunName
    path => '.1.3.6.1.2.1.25.4.2.1.4', # hrSWRunPath
    args => '.1.3.6.1.2.1.25.4.2.1.5', # hrSWRunParameters (Warning: it's truncated. (128 characters))
    status => '.1.3.6.1.2.1.25.4.2.1.7', # hrSWRunStatus
};

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    use Data::Dumper;
   
    # Get process names
    my $result = $self->{snmp}->get_table(oid => $oids->{'name'});
    my $result_args = $self->{snmp}->get_table(oid => $oids->{'args'});

    my $processcount = 0;
    my $processname = $self->{option_results}->{process_name};

    # Check regexp name
    if ($self->{option_results}->{regexp_name}) {
	foreach my $key (keys %{ $result }) {
	    if ($result->{$key} =~ m/$processname/gi) {
		if (($self->{option_results}->{process_args}) &&  ($self->{option_results}->{process_args} ne '')) {
			my $processargs = $self->{option_results}->{process_args};

			# Get process OID
			my $process_id = $key;
			$process_id =~ s/$oids->{'name'}//gi;

			$process_id = $oids->{'args'}.$process_id;

			if ($result_args->{$process_id}) {
				if ($self->{option_results}->{regexp_args}) {
					if ($result_args->{$process_id} =~ m/$processargs/gi) {
						$processcount++;
					}
				} else {
					if ($result_args->{$process_id} eq $processargs) {
						$processcount++;
					}
				}
			}
		} else {
		        $processcount++;
		}
	    }
        }

    # Check name
    } else {
        foreach my $key (keys %{ $result }) {
            if ($result->{$key} eq $processname) {
                if (($self->{option_results}->{process_args}) && ($self->{option_results}->{process_args} ne '')) {
                        my $processargs = $self->{option_results}->{process_args};

			# Get process OID
			my $process_id = $key;
                        $process_id =~ s/$oids->{'name'}//gi;

                        $process_id = $oids->{'args'}.$process_id;

                        if ($result_args->{$process_id}) {
                                if ($self->{option_results}->{regexp_args}) {
                                        if ($result_args->{$process_id} =~ m/$processargs/gi) {
                                                $processcount++;
                                        }
                                } else {
                                        if ($result_args->{$process_id} eq $processargs) {
                                                $processcount++;
                                        }
                                }
                        }
                } else {
                        $processcount++;
                }
	    }
        }
    }

    my $severity = 'OK';

    if (($self->{option_results}->{critical}) && ($processcount < $self->{option_results}->{critical})) {
	$severity = 'CRITICAL';
    } elsif (($self->{option_results}->{warning}) && ($processcount < $self->{option_results}->{warning})) {
        $severity = 'WARNING';
    }

    # Print output
    $self->{output}->output_add(severity => $severity, short_msg => sprintf ("Number of current processes '%s' running: %s", $processname, $processcount));

    $self->{output}->perfdata_add(label => 'nbproc',
    				  value => $processcount);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system number of processes.
Can also check memory usage and cpu usage.

=over 8

=item B<--warning>

Threshold warning (process count).

=item B<--critical>

Threshold critical (process count).

=item B<--process-name>

Check process name.

=item B<--regexp-name>

Allows to use regexp to filter process name (with option --process-name).

=item B<--process-path>

Check process path.

=item B<--regexp-path>

Allows to use regexp to filter process path (with option --process-path).

=item B<--process-args>

Check process args.

=item B<--regexp-args>

Allows to use regexp to filter process args (with option --process-args).

=back

=cut
