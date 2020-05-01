package custom::apps::vmware::nsx_controller::mode::swap;

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
									"controller:s"	=> { name => 'controller' },
									"warning:s"		=> { name => 'warning' },
									"critical:s"	=> { name => 'critical' },
									"hostname:s"	=> { name => 'hostname' },
									"username:s"	=> { name => 'username' },
									"password:s"	=> { name => 'password' },
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
    my $controller = $self->{option_results}->{controller};

    # Get controller ID
    my $url = 'api/2.0/vdn/controller';
    my $xml = `curl -u $username:$password https://$hostname/$url -k -s`;
    my $data = XMLin($xml);

    my $controller_id;

    if (exists($data->{controller}->{$controller}->{id})) {
        $controller_id = $data->{controller}->{$controller}->{id};
    } else {
        $self->{output}->add_option_msg(short_msg => "Unknown controller name : $controller.");
        $self->{output}->option_exit();
    }

    # Get controller swap
    $url = "api/2.0/vdn/controller/$controller_id/systemStats";
    $xml = `curl -u $username:$password https://$hostname/$url -k -s`;

    $data = XMLin($xml);


    my $used_swap = $data->{usedSwap};
    my $total_swap = $data->{totalSwap};
    my $swap_used = $used_swap / $total_swap * 100;


    my $exit = $self->{perfdata}->threshold_check(value => $swap_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Used Swap: %.2f%%", $swap_used));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $used_swap,
                                  min => 0, max => $total_swap);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VMWare NSX Controller SWAP.

=over 8

=item B<--hostname>

VMWare NSX Controller hostname.

=item B<--username>

VMWare NSX Controller login.

=item B<--password>

VMWare NSX Controller password.

=item B<--controller>

VMWare NSX Controller name.

=item B<--warning>

Warning threshold (percentage).

=item B<--critical>

Critical threshold (percentage).

=back

=cut
