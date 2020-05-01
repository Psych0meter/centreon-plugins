package custom::database::mssql::mode::alwayson;

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

    my $alert = 0;
    my $severity = 'OK';
    my $message = '';
    my $result;

    # Check AlwaysOn DB    $self->{sql}->query(query => q{ SELECT name
    $self->{sql}->query(query => q{ SELECT *
                                    FROM sys.databases
                                    WHERE replica_id IS NULL
                                    AND name NOT IN ('master', 'tempdb', 'model', 'msdb') and Name not like '%_noHA'});

    $result = $self->{sql}->fetchall_arrayref();

    my $db_list;
    my $array_size = @$result;
    my $index = 1;

    foreach my $row (@$result) {
        $db_list .= $$row[0];
        $db_list .= " / " if ($index < $array_size);
        $index++;
    }

    $message = 'DB status : ';
    if ($db_list eq '') {
        $message .= 'OK';
    } else {
        $message .= $db_list." not replicated";
        $alert++;
    }

    # Check AlwaysOn Members
    $self->{sql}->query(query => q{ SELECT member_name, member_state, member_state_desc
                                    FROM sys.dm_hadr_cluster_members });

    $result = $self->{sql}->fetchall_arrayref();

    $message .= ", Members : ";

    $array_size = @$result;
    $index = 1;

    foreach my $row (@$result) {
        my $name = $$row[0];
        my $status = $$row[2];
        $alert++ if ($$row[1] ne '1');
                                     
        $message .= $name." is ".$status;
        $message .= " / " if ($index < $array_size);
        $index++;
    }

    # Check AlwaysOn Replica States
    $self->{sql}->query(query => q{ SELECT name, replica_server_name, synchronization_state, synchronization_state_desc, synchronization_health, synchronization_health_desc
                                    FROM sys.dm_hadr_database_replica_states
                                    INNER JOIN sys.availability_replicas ON dm_hadr_database_replica_states.replica_id = availability_replicas.replica_id
                                    INNER JOIN sys.databases ON dm_hadr_database_replica_states.database_id = databases.database_id });


    $result = $self->{sql}->fetchall_arrayref();

    $message .= ", Replica States : ";

    $array_size = @$result;
    $index = 1;

    foreach my $row (@$result) {
        my $db_name = $$row[0];
        my $server_name = $$row[1];
        my $sync = $$row[3];
        my $health = $$row[5];

        $alert++ if (($$row[2] ne 2) || ($$row[4] ne 2));

        $message .= $db_name." on ".$server_name." is ".$sync." and ".$health;
        $message .= " / " if ($index < $array_size);
        $index++;
    }

    # Set severity
    $severity = "CRITICAL" if ($alert > 0);

    $self->{output}->output_add(severity => $severity,
                                  short_msg => $message);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MSSQL db alwaysOn.

=over 8

=back

=cut
