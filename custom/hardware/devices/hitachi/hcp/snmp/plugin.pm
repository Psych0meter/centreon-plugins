package custom::hardware::devices::hitachi::hcp::snmp::plugin;

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
                'node' 			=> 'custom::hardware::devices::hitachi::hcp::snmp::mode::node',
                'node_status'   => 'custom::hardware::devices::hitachi::hcp::snmp::mode::node_status',
                'node_nic'      => 'custom::hardware::devices::hitachi::hcp::snmp::mode::node_nic',
                'pool' 			=> 'custom::hardware::devices::hitachi::hcp::snmp::mode::pool',
				'storage'		=> 'custom::hardware::devices::hitachi::hcp::snmp::mode::storage',
                'url'           => 'custom::hardware::devices::hitachi::hcp::snmp::mode::url',
        );

        return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Plugin to monitor Hitachi HCP Server
Requires : 
- LWP::UserAgent
- Switch

=cut
