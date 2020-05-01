package custom::os::windows::snmp::plugin;

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
							'service'	=> 'custom::os::windows::snmp::mode::service',
							'memory'	=> 'custom::os::windows::snmp::mode::memory',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Windows operating systems with SNMP.

=cut
