package custom::network::checkpoint::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;

	# Plugin version
	$self->{version} = '0.1';

	# Plugin modes
	%{$self->{modes}} = (
		'vs-activeconnections'	=> 'custom::network::checkpoint::snmp::mode::vsactiveconnections',
		'vs-cpu'				=> 'custom::network::checkpoint::snmp::mode::vscpu',
	);

	return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

CheckPoint plugin.

=cut
