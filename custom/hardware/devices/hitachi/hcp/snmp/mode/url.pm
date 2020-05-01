package custom::hardware::devices::hitachi::hcp::snmp::mode::url;

use base qw(centreon::plugins::mode);

use LWP::UserAgent;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_ip			= '.1.3.6.1.4.1.116.5.46.1.1.1.2';

    my $result;

    # Get IP list
    my $result_ip = $self->{snmp}->get_table(oid => $oid_ip);
    foreach my $oid (keys %{$result_ip}) {
	my $id = $oid;
	$id =~ s/.*\.(\d+)$/$1/gi;
	$result->{$id}->{"ip"} = $result_ip->{$oid};
    }


    my $critical = 0;
    my $output = "";
    my $output_long = "";

    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->env_proxy;

    foreach my $id (sort keys %{$result}) {
	my $ip = $result->{$id}->{"ip"};
	my $url = "http://$ip/node_status";

	my $response = $ua->get($url);

	my $return_code = $response->{"_rc"};

	if ($return_code ne '204') {
		$output .= " / " if ($critical > 0);
		$critical++;
		$output .= "$url returns $return_code";
	}

	$output_long .= "$url returns $return_code\n";
    }

    my $exit = "OK";
    $exit = "CRITICAL" if ($critical > 0);
    $output = "All URLs are OK" if ($output eq "");

    $self->{output}->output_add(        severity => $exit,
                                        short_msg => $output,
                                        long_msg => $output_long);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__
