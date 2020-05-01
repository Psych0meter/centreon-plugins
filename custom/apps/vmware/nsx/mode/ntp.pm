package custom::apps::vmware::nsx::mode::ntp;

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
                                  "hostname:s"              => { name => 'hostname' },
                                  "username:s"              => { name => 'username' },
                                  "password:s"              => { name => 'password' },
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

    my $url = 'api/1.0/appliance-management/system/timesettings';

    my $xml = `curl -u $username:$password https://$hostname/$url -k -s`;

    my $data = XMLin($xml);

    my $date = $data->{datetime};

    $self->{output}->output_add(severity => "OK",
                                short_msg => sprintf("Date: %s", $date));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VMWare NSX NTP.

=over 8

=item B<--hostname>

VMWare NSX hostname.

=item B<--username>

VMWare NSX login.

=item B<--password>

VMWare NSX password.

=back

=cut