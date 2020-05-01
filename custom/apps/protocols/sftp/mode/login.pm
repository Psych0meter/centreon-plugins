package custom::apps::protocols::sftp::mode::login;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Net::SFTP::Foreign;
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
			"hostname:s"	=> { name => 'hostname' },
			"port:s"		=> { name => 'port', },
			"username:s"	=> { name => 'username' },
			"password:s"	=> { name => 'password' },
			"warning:s"		=> { name => 'warning' },
			"critical:s"	=> { name => 'critical' },
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

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    my $sftp = Net::SFTP::Foreign->new(	$self->{option_results}->{hostname}, 
					port => $self->{option_results}->{port}, 
					user => $self->{option_results}->{username}, 
					password => $self->{option_results}->{password});

    if ($sftp->{_error} ne '0') {
	$self->{output}->output_add(	severity => 'CRITICAL',
					short_msg => $sftp->{_error});
    } else {
	    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
	    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
   	 $self->{output}->output_add(severity => $exit,
	                                short_msg => sprintf("Response time %.3f ", $timeelapsed));
	    $self->{output}->perfdata_add(label => "time",
	                                  value => sprintf('%.3f', $timeelapsed),
	                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
	                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Connection (also login) to a SFTP Server.

=over 8

=item B<--hostname>

IP Addr/FQDN of the ftp host

=item B<--port>

Port used

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
