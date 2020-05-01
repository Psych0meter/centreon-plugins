package custom::database::mssql::mode::running;

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
                                 });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    #$options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    $self->{sql}->query(query => q{ select servicename AS ServiceName
       ,startup_type_desc AS StartupType
       ,status_desc AS ServiceStatus
       ,process_id AS ProcessID
       ,last_startup_time AS LastStartupTime
       ,service_account AS ServiceAccount
FROM sys.dm_server_services
Where ServiceName like 'SQL Server (%)'});

    my $severity = 'OK';
    my $outputmessage = '';

    my $result = $self->{sql}->fetchall_arrayref();
    foreach my $row (@$result) {
        if ($$row[2] ne 'Running') {
                $outputmessage .= $$row[0] . ",";
        }
    }

    my $finalmessage = 'Service(s) not running : ';
    if ($outputmessage eq '') {
        $finalmessage = 'All Services are OK.';
    }
    else {
        $finalmessage = substr $outputmessage, 0, -1;
        $severity = 'CRITICAL';
    }

    $self->{output}->output_add(severity => $severity,
                                  short_msg => $finalmessage);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MSSQL Service not Running.

=over 8

=back

=cut
