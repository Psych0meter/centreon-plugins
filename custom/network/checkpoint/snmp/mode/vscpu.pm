package custom::network::checkpoint::snmp::mode::vscpu;

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
                                  "vs-name:s"             => { name => 'vs-name', default => '' },
                                  "warning:s"               => { name => 'warning', default => 70 },
                                  "critical:s"              => { name => 'critical', default => 90 },

                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if ( !defined($self->{option_results}->{'vs-name'}) ){
        $self->{output}->add_option_msg(short_msg => "You need to specify a Virtual Server Name.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    # OIDs
    my $oid_vs_name = '.1.3.6.1.4.1.2620.1.16.22.1.1.3';
    my $oid_vs_cpu = '.1.3.6.1.4.1.2620.1.16.22.2.1.3';

    # Get requests
    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vs_name },
                                                            { oid => $oid_vs_cpu },
                                                         ],
                                                         , nothing_quit => 1);

    my $cpu_usage = 0;
    my $vs_id = '';

    my $severity = 'OK';
    my $output;

    foreach my $key ( keys %{$self->{results}->{$oid_vs_name}} ) {
       if ($self->{results}->{$oid_vs_name}->{$key} =~ m/$self->{option_results}->{'vs-name'}/ ) {
            $vs_id = $key;
            $vs_id =~ s/$oid_vs_name//gi;
            last;
       }
    }

    if ($vs_id eq '') {
        $severity = 'UNKNOWN';
        $output = 'Error getting Virtual Server ID.';
    } else {
        $cpu_usage = $self->{results}->{$oid_vs_cpu}->{$oid_vs_cpu.$vs_id};
        $output = "Virtual Server CPU Usage for ".$self->{option_results}->{'vs-name'}.": ".$cpu_usage;

        $self->{output}->perfdata_add(label => '%',
                                      value => $cpu_usage);
    }

    if ($cpu_usage >= $self->{option_results}->{'critical'}) {
        $severity = 'CRITICAL';
    } elsif ($cpu_usage >= $self->{option_results}->{'warning'}) {
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

Check VS CPU

=over 8

=item B<--vs-name>

VS name

=item B<--critical>

Critical threshold.

=item B<--warning>

Warning threshold.

=back

=cut