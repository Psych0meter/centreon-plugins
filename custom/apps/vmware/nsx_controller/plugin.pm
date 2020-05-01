package custom::apps::vmware::nsx_controller::plugin;

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
							'memory'	=> 'custom::apps::vmware::nsx_controller::mode::memory',
							'ntp'		=> 'custom::apps::vmware::nsx_controller::mode::ntp',
							'swap'		=> 'custom::apps::vmware::nsx_controller::mode::swap',
							'uptime'	=> 'custom::apps::vmware::nsx_controller::mode::uptime',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check VMWare Controller
Requires : XML::Simple

=cut
