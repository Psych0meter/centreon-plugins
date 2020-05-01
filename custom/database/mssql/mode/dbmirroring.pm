package custom::database::mssql::mode::dbmirroring;

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
					"filter:s"                => { name => 'filter', },
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

    $self->{sql}->query(query => q{	SELECT DB_NAME(database_id) As DatabaseName,
					    CASE WHEN mirroring_guid IS NOT NULL THEN '1' ELSE '0' END AS IsMirrorOn, mirroring_state_desc,
					    CASE WHEN mirroring_safety_level=1 THEN 'High Performance' WHEN mirroring_safety_level=2 THEN 'High Safety' ELSE NULL END AS MirrorSafety,
						mirroring_role_desc, mirroring_partner_instance AS MirrorServer
					FROM sys.database_mirroring}); 


    my $severity = 'UNKNOWN';
    my $outputmessage = '';

    my @not_synched;
    my @mirror_servers;

    my $result = $self->{sql}->fetchall_arrayref();
    foreach my $row (@$result) {

	next if (defined($self->{option_results}->{filter}) && $$row[0] !~ /$self->{option_results}->{filter}/);

	my $DatabaseName = $$row[0];
        my $IsMirrorOn   = $$row[1];

	# Check if database is mirrored
	if ($IsMirrorOn eq '1') { 
                my $MirroringState = $$row[2] ;
                my $MirrorSafety = $$row[3];
                my $Mirorring_role_desc = $$row[4];
                my $MirrorServer = $$row[5];

		#$outputmessage .= "Database ".$DatabaseName." is ".$MirroringState." (".$MirrorSafety.") on ".$MirrorServer." (".$Mirorring_role_desc.")";

		if (!( grep( /^$Mirorring_role_desc$/, @mirror_servers) )) {
			push(@mirror_servers, $Mirorring_role_desc);
		}
	} else {
		#$outputmessage .= "Database ".$DatabaseName." : No mirror configured";
		push(@not_synched, $DatabaseName);
	}
    }

    # Databases are synchronized
    if ((scalar @not_synched eq 0) && (scalar @mirror_servers eq 1)) {
	$severity = 'OK';
	$outputmessage .= "All databases are synchronized";
    } else {
	    $severity = 'CRITICAL';

	    # Some databases are not synchronized
	    if (scalar @not_synched > 0) {
		my $databases = join(", ", @not_synched);
		$outputmessage .= $databases." : No mirror configured";
	    } 

	    # All databases are not on the same node
	    if (scalar @mirror_servers > 1) {
		$outputmessage .= ". " if ($outputmessage ne '');
		$outputmessage .= "Principal server not the same for all databases";
	    }
    }

    $self->{output}->output_add(severity => $severity,
                                  short_msg => $outputmessage);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MSSQL db mirroring.

=over 8

=back

=cut
