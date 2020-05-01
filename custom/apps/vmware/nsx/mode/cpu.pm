package custom::apps::vmware::nsx::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use XML::Simple;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
									"warning:s"		=> { name => 'warning' },
									"critical:s"  	=> { name => 'critical' },
									"hostname:s"  	=> { name => 'hostname' },
									"username:s"   	=> { name => 'username' },
									"password:s"   	=> { name => 'password' },
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

    if ($self->{option_results}->{username} eq '') {
		$self->{output}->add_option_msg(short_msg => "Username not specified.");
		$self->{output}->option_exit();
    }
    if ($self->{option_results}->{password} eq '') {
		$self->{output}->add_option_msg(short_msg => "Password not specified.");
		$self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $hostname = $self->{option_results}->{host};
    my $username = $self->{option_results}->{username};
    my $password = $self->{option_results}->{password};

    my $url = 'api/1.0/appliance-management/system/cpuinfo';

    my $xml = `curl -u $username:$password https://$hostname/$url -k -s`;

    my $data = XMLin($xml);

    my $used_cpu = $data->{usedPercentage};

    my $exit = $self->{perfdata}->threshold_check(value => $used_cpu, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Used CPU: %s%%", $used_cpu));

    $self->{output}->perfdata_add(label => "used", unit => '%',
                                  value => $used_cpu,
                                  min => 0, max => 100);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VMWare NSX CPU.

=over 8

=item B<--hostname>

VMWare NSX hostname.

=item B<--username>

VMWare NSX login.

=item B<--password>

VMWare NSX password.

=item B<--warning>

Warning threshold (percentage).

=item B<--critical>

Critical threshold (percentage).

=back

=cut