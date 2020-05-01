package custom::apps::protocols::http::mode::responsentlm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use centreon::plugins::http;
use Time::HiRes qw(gettimeofday tv_interval);
use WWW::Curl::Easy;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.2';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"		=> { name => 'hostname' },
            "port:s"			=> { name => 'port', },
            "proto:s"			=> { name => 'proto' },
            "url:s"				=> { name => 'url' },
			"proxy-host:s"		=> { name => 'proxy_host' },
	    	"proxy-port:s"		=> { name => 'proxy_port' },
            "proxy-username:s"	=> { name => 'proxy_user' },
            "proxy-password:s"	=> { name => 'proxy_password' },
            "warning:s"			=> { name => 'warning' },
            "critical:s"		=> { name => 'critical' },
            });
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{proxy_host})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --proxy-host option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{proxy_port})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --proxy-port option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{proxy_user})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --proxy-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{proxy_host})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --proxy-password option.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];

    open(NULLFILE,">/dev/null") or die;

    my $curl_geturl = WWW::Curl::Easy->new;
    $curl_geturl->setopt(CURLOPT_HEADER,0);
    $curl_geturl->setopt(CURLOPT_PROXY,$self->{option_results}->{proxy_host});
    $curl_geturl->setopt(CURLOPT_PROXYPORT,$self->{option_results}->{proxy_port});
    $curl_geturl->setopt(CURLOPT_PROXYUSERPWD,$self->{option_results}->{proxy_user} . ":" . $self->{option_results}->{proxy_password});
    $curl_geturl->setopt(CURLOPT_URL,$self->{option_results}->{url});
    $curl_geturl->setopt(CURLOPT_WRITEDATA, *NULLFILE);
    $curl_geturl->setopt(CURLOPT_VERBOSE, 0);
    $curl_geturl->perform;

    my $return_code = $curl_geturl->perform;

    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
   
    if ($return_code == 0) {
	my $response_code = $curl_geturl->getinfo(CURLINFO_HTTP_CODE);
	
        if ($response_code eq "200") {
		my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
		$self->{output}->output_add(	severity => $exit,
                                        	short_msg => sprintf("Response time %.3fs (HTTP Code : %s)", $timeelapsed, $response_code));
        	$self->{output}->perfdata_add(	label => "time",
                                         	value => sprintf('%.3f', $timeelapsed),
                                          	warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                          	critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

#                $self->{output}->output_add(    severity => 'OK',
#                                                short_msg => sprintf("Successful HTTP request from proxy (HTTP Code : %s)", $response_code));
	} else {
		$self->{output}->output_add(	severity => 'CRITICAL',
						short_msg => sprintf("Unable to fetch url through proxy (HTTP Error Code : %s)", $response_code));
	}
    } else {
 	$self->{output}->output_add(    severity => 'CRITICAL',
                                        short_msg => sprintf("Unable to make an HTTP request through proxy (HTTP Error Code : %s)", $return_code));
    }

    $curl_geturl->cleanup();
    close NULLFILE;

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Webpage content

=over 8

=item B<--hostname>

IP Addr/FQDN of the Webserver host

=item B<--port>

Port used by Webserver

=item B<--proxy-host>

Proxy host

=item B<--proxy-port>

Proxy port

=item B<--proxy-username>

Proxy username

=item B<--proxy-password>

Proxy password

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--url>

Set path to get Webpage (Default: '/')

=item B<--warning>

Threshold warning in seconds (Webpage response time)

=item B<--critical>

Threshold critical in seconds (Webpage response time)

=back

=cut
