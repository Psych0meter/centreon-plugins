package custom::apps::protocols::x509::mode::validity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Crypt::OpenSSL::X509;
use Date::Calc qw(Delta_Days Parse_Date Today);
use Getopt::Long;



sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.4';
    $options{options}->add_options(arguments =>
         {
			"hostname:s"	=> { name => 'hostname' },
			"port:s"		=> { name => 'port', default => '443' },
			"servername:s"	=> { name => 'servername', default => '' },
			"warning:i"		=> { name => 'warning', default => '60' },
			"critical:i"	=> { name => 'critical', default => '30' },
			"openssl:s"		=> { name => 'openssl', default => '/usr/bin/openssl' },
			"starttls:s"	=> { name => 'starttls', default => '' },
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


    # Retrieve certificate
    my $certificate = '';

    my $sniPart = '';

    if ( $self->{option_results}->{servername} ne '' ) {
	$sniPart = sprintf("-servername %s", $self->{option_results}->{servername});
    } else {
        $sniPart = sprintf("-servername %s", $self->{option_results}->{hostname});
    }

    # Check if we have to set starttls protocol
    my $starttlsPart = '';
    
    if ( $self->{option_results}->{starttls} ne '' ) {
	$starttlsPart = sprintf("-starttls %s", $self->{option_results}->{starttls});
    }

    # Build command
    my $command = sprintf( "echo \"\" | %s s_client -connect %s:%d %s %s 2> /dev/null | %s x509 2> /dev/null",
	$self->{option_results}->{openssl},
	$self->{option_results}->{hostname},
        $self->{option_results}->{port},
        $starttlsPart,
        $sniPart,
        $self->{option_results}->{openssl},
    );


    $certificate = `$command`;

    # Check if certificate is returned
    if ($certificate eq '') {
	$self->{output}->output_add(	severity => 'CRITICAL',
				        short_msg => sprintf("Unable to get a certificate on %s:%s", $self->{option_results}->{hostname}, $self->{option_results}->{port}));
    } else {
		my $x509 = Crypt::OpenSSL::X509->new_from_string($certificate, Crypt::OpenSSL::X509::FORMAT_PEM);

		# Check date of certificate
		my $date_certificate = $x509->notAfter();
		my ($year, $month, $day) = Parse_Date($date_certificate);
		my ($nowYear, $nowMonth, $nowDay) = Today();

		# Delta
		my $delta = Delta_Days($nowYear, $nowMonth, $nowDay, $year, $month, $day);

		if ($delta <= 0) {
			$self->{output}->output_add(severity => 'CRITICAL',
										short_msg => sprintf("Certificate is expired : %s", $date_certificate));
		} elsif ($delta <= $self->{option_results}->{critical}) {
					$self->{output}->output_add(severity => 'CRITICAL',
												short_msg => sprintf("%d days left : %s", $delta, $date_certificate));
		} elsif ($delta <= $self->{option_results}->{warning}) {
					$self->{output}->output_add(severity => 'WARNING',
												short_msg => sprintf("%d days left : %s", $delta, $date_certificate));
		} else {
					$self->{output}->output_add(severity => 'OK',
												short_msg => sprintf("%d days left : %s", $delta, $date_certificate));
		}
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check X509's certificate validity (for SMTPS, POPS, IMAPS, HTTPS)

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--servername>

Servername of the host for SNI support (only with IO::Socket::SSL >= 1.56) (eg: foo.bar.com)

=item B<--port>

Port used by Server

=item B<--warning>

Threshold warning in days (Days before expiration, eg: '60:' for 60 days before)

=item B<--starttls>

Set TLS Options (eg: smtp).

=back

=cut

