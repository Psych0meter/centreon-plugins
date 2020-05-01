package custom::network::f5::bigip::snmp::plugin;

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
							'requests'		=> 'custom::network::f5::bigip::snmp::mode::request',
							'response-code'	=> 'custom::network::f5::bigip::snmp::mode::response',
							'memory'		=> 'custom::network::f5::bigip::snmp::mode::memory',
							'connections'	=> 'custom::network::f5::bigip::snmp::mode::connections',
							'member'		=> 'custom::network::f5::bigip::snmp::mode::member',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check F5 hardware with SNMP.
Requires: IO::Socket

=cut
