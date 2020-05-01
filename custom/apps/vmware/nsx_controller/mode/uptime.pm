package custom::apps::vmware::nsx_controller::mode::uptime;

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
									"hostname:s"	=> { name => 'hostname' },
									"username:s"	=> { name => 'username' },
									"password:s"	=> { name => 'password' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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

    # Get controller uptime
    $url = "api/2.0/vdn/controller/$controller_id/systemStats";
    $xml = `curl -u $username:$password https://$hostname/$url -k -s`;

    $data = XMLin($xml);


    my $uptime = $data->{upTime};

    $self->{output}->output_add(severity => "OK",
                                short_msg => sprintf("Uptime : %ss", $uptime));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VMWare NSX Controller uptime.

=over 8

=item B<--hostname>

VMWare NSX Controller hostname.

=item B<--username>

VMWare NSX Controller login.

=item B<--password>

VMWare NSX Controller password.

=item B<--controller>

VMWare NSX Controller name.

=back

=cut