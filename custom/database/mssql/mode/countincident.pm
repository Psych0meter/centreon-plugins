package custom::database::mssql::mode::countincident;

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
                                  "incidenttype:s"          => { name => 'incidenttype'},
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
    if (!defined($self->{option_results}->{incidenttype}) || $self->{option_results}->{incidenttype} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--incidenttype' option.");
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
    my $value2 = $value;
    $value2 =~ s/.{6}$//;
    my $sqldate = Time::Piece->strptime($value2, $self->{option_results}->{format}); # "%b %d %Y %H:%M:%S"
    # Today
    my $now = localtime;

    # Delta
    my $diff = $now - $sqldate;
    if ($value=~ /PM/) {
        $diff=$diff-43200;
    }
    my $delta = int($diff->days) . " day(s) ". ($diff->hours)%24 . " hour(s) " . ($diff->minutes)%60 . " minute(s)";
    my $severity = "OK";

    my $message = "Last ".$self->{option_results}->{incidenttype}. " " . $delta;

    $self->{output}->output_add(severity => $severity,
                                short_msg => $message);
    $self->{output}->perfdata_add(label => 'days', unit => undef,
                                value => int($diff->days),
                                );
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SQL statement.
Specific for Axios Assyst software

=over 8

=item B<--sql-statement>

SQL statement that returns a number.

=item B<--format>

Date format (Example : "%b %d %Y %H:%M:%S")

=item B<--incidenttype>

Incident type (Example: 'P1').

=back

=cut
