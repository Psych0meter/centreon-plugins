package custom::apps::protocols::http::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;
# $options->{options} = options object

	$self->{version} = '0.1';
	%{$self->{modes}} = (
				'expected-contentwiththreshold'	=> 'custom::apps::protocols::http::mode::expectedcontentwiththreshold',
				'response-ntlm'					=> 'custom::apps::protocols::http::mode::responsentlm',
			);

	return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check HTTP or HTTPS webpage.
Requires : 
- centreon::plugins::http
- Time::HiRes
- WWW::Curl::Easy

=cut
