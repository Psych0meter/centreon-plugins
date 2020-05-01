package custom::os::linux::snmp::plugin;

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
							'memory'		=> 'custom::os::linux::snmp::mode::memory',
							'snmp-exec'		=> 'custom::os::linux::snmp::mode::snmpexec',
							'snmp-extend'	=> 'custom::os::linux::snmp::mode::snmpextend',
							'swap'			=> 'custom::os::linux::snmp::mode::swap',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Linux operating systems with SNMP.

=cut
