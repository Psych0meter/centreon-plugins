package custom::centreon::common::protocols::sql::mode::sql;

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
									"sql-statement:s"	=> { name => 'sql_statement', },
									"format:s"			=> { name => 'format', default => 'SQL statement result : %i.'},
									"perfdata-unit:s"	=> { name => 'perfdata_unit', default => ''},
									"perfdata-name:s"	=> { name => 'perfdata_name', default => 'value'},
									"perfdata-min:s"	=> { name => 'perfdata_min', default => ''},
									"perfdata-max:s"	=> { name => 'perfdata_max', default => ''},
									"ok:s"				=> { name => 'ok', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{sql_statement}) || $self->{option_results}->{sql_statement} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--sql-statement' option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{format}) || $self->{option_results}->{format} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--format' option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    my $query = $self->{option_results}->{sql_statement};

    $self->{sql}->connect();
    $self->{sql}->query(query => $query);
    my $value = $self->{sql}->fetchrow_array();

    my $exit_code = 'CRITICAL';

    $exit_code = 'OK' if ($value eq $self->{option_results}->{ok});

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf($self->{option_results}->{format}, $value));
    $self->{output}->perfdata_add(label => $self->{option_results}->{perfdata_name},
                                  unit => $self->{option_results}->{perfdata_unit},
                                  value => $value,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => $self->{option_results}->{perfdata_min},
                                  max => $self->{option_results}->{perfdata_max});

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SQL statement.

=over 8

=item B<--sql-statement>

SQL statement that returns a number.

=item B<--format>

Output format (Default: 'SQL statement result : %i.').

=item B<--perfdata-unit>

Perfdata unit in perfdata output (Default: '')

=item B<--perfdata-name>

Perfdata name in perfdata output (Default: 'value')

=item B<--perfdata-min>

Minimum value to add in perfdata output (Default: '')

=item B<--perfdata-max>

Maximum value to add in perfdata output (Default: '')

=item B<--ok>

Returns OK if SQL statement match OK value

=back

=cut

