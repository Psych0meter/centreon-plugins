package custom::network::cisco::standard::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '1.0';
    %{$self->{modes}} = (
							'bgp'		=> 'custom::centreon::common::cisco::standard::snmp::mode::bgp',
							'topology'	=> 'custom::centreon::common::cisco::standard::snmp::mode::topology',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco equipments in SNMP.
Requires : 
- custom::centreon::common::cisco::standard::snmp::mode::bgp
- custom::centreon::common::cisco::standard::snmp::mode::topology

=cut
