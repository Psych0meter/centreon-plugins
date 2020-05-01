package custom::snmp_standard::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'interfaces'      	 	=> 'custom::snmp_standard::mode::interfaces',
                         'processcount'     	=> 'custom::snmp_standard::mode::processcount',
                         'memory'           	=> 'custom::snmp_standard::mode::memory',
                         'psc_memory'       	=> 'custom::snmp_standard::mode::psc_memory',
                         'storage_cap_planning' => 'custom::snmp_standard::mode::storage_cap_planning',
                         'storage_dev'      	=> 'custom::snmp_standard::mode::storage_dev',
                         'storage'          	=> 'custom::snmp_standard::mode::storage',
                         'throughput'       	=> 'custom::snmp_standard::mode::throughput',
                         'vip'              	=> 'custom::snmp_standard::mode::vip',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Standard plugins with SNMP
Requires : 
- centreon::plugins::statefile
- IO::Socket
- Switch;

=cut
