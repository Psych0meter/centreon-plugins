package custom::database::mssql::mode::sqldate;

use base qw(centreon::plugins::mode);

use Time::Piece;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "sql-statement:s"         => { name => 'sql_statement', },
                                  "format:s"                => { name => 'format'},
                                  "warning:s"               => { name => 'warning', default =>60},
                                  "critical:s"              => { name => 'critical', default => 30},
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

    # Date in database
    my $sqldate = Time::Piece->strptime($value, $self->{option_results}->{format}); # "%b %d %Y %H:%M:%S:000PM"
    # Today
    my $now = localtime;
   
    # Delta
    my $diff = $sqldate - $now;
    my $delta = int($diff->days);

    my $severity = "UNKNOWN";
 
    # Thresholds
    if ($delta <= $self->{option_results}->{critical}) {
	$severity = "CRITICAL";	
    } elsif ($delta <= $self->{option_results}->{warning}) {
	$severity = "WARNING";
    } else {
	$severity = "OK";
    }

    my $message = "$delta days remaining until '$value'"; 

    $self->{output}->output_add(severity => $severity,
                                short_msg => $message);

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

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
